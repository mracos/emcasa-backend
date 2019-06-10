defmodule ReIntegrations.Orulo.PayloadsProcessor do
  @moduledoc """
  Module to process payloads into internal representations.
  """

  alias Ecto.Multi

  alias Re.{
    Developments,
    DevelopmentTag,
    Tags
  }

  alias ReIntegrations.{
    Cloudinary,
    Orulo.BuildingPayload,
    Orulo.ImagePayload,
    Orulo.JobQueue,
    Orulo.Mapper,
    Orulo.TagMapper,
    Repo
  }

  def insert_development_from_building_payload(multi, building_uuid) do
    building = Repo.get(BuildingPayload, building_uuid)

    multi
    |> insert_address(building)
    |> insert_development(building)
    |> enqueue_image_job(building)
    |> enqueue_tag_job(building)
    |> Repo.transaction()
  end

  defp insert_address(multi, building) do
    Multi.run(multi, :insert_address, fn _repo, _changes ->
      building
      |> Mapper.building_payload_into_address_params()
      |> Re.Addresses.insert_or_update()
    end)
  end

  defp insert_development(multi, building) do
    Multi.run(multi, :insert_development, fn _repo, %{insert_address: address} ->
      building
      |> Mapper.building_payload_into_development_params()
      |> Re.Developments.insert(address)
    end)
  end

  defp enqueue_image_job(multi, building) do
    JobQueue.enqueue(multi, :fetch_images, %{
      "type" => "fetch_images_from_orulo",
      "external_id" => building.external_id
    })
  end

  defp enqueue_tag_job(multi, building) do
    JobQueue.enqueue(multi, :process_tags, %{
      "type" => "process_orulo_tags",
      "external_id" => building.uuid
    })
  end

  def insert_images_from_image_payload(multi, payload_uuid) do
    %{payload: %{"images" => image_payload}, external_id: orulo_id} =
      Repo.get(ImagePayload, payload_uuid)

    {:ok, development} = get_development_by_orulo_id(orulo_id)

    images_upload_response =
      image_payload
      |> extract_url_list_from_payload()
      |> upload_images()

    multi
    |> Multi.run(:insert_images, fn _repo, _changes ->
      case images_upload_response do
        [] ->
          Sentry.capture_message("images_upload_failed",
            extra: %{payload_uuid: payload_uuid, payload: image_payload}
          )

          {:error, "Could not upload development images."}

        _ ->
          saved_images =
            images_upload_response
            |> extract_images_params_from_response()
            |> save_images(development)

          {:ok, saved_images}
      end
    end)
    |> Repo.transaction()
  end

  defp upload_images(image_urls), do: Cloudinary.Client.upload(image_urls)

  @resolution "1024x1024"
  defp extract_url_list_from_payload(image_payload) do
    image_payload
    |> Enum.map(fn image -> Map.get(image, @resolution) end)
  end

  defp save_images(image_names, development) do
    image_names
    |> Enum.map(&Re.Images.insert(&1, development))
  end

  defp extract_images_params_from_response(uploaded_images) do
    uploaded_images
    |> Enum.map(&mount_filename_from_response/1)
    |> Enum.map(fn filename -> %{filename: filename} end)
  end

  defp mount_filename_from_response({:ok, %{public_id: public_id, format: format}}),
    do: "#{public_id}.#{format}"

  def get_development_by_orulo_id(orulo_id) do
    case Developments.get_by_orulo_id(Integer.to_string(orulo_id)) do
      {:ok, development} ->
        {:ok, Developments.preload(development, [:images])}

      error ->
        error
    end
  end

  def process_orulo_tags(multi, uuid) do
    %{payload: %{"id" => external_id}} = building = Repo.get(BuildingPayload, uuid)
    {:ok, development} = Developments.get_by_orulo_id(external_id)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    developments_tags =
      building
      |> TagMapper.map_tags()
      |> Tags.list_by_slugs()
      |> Enum.map(fn tag ->
        %{
          development_uuid: development.uuid,
          tag_uuid: tag.uuid,
          inserted_at: now,
          updated_at: now
        }
      end)

    multi
    |> Multi.insert_all(:insert_tags, DevelopmentTag, developments_tags)
    |> Re.Repo.transaction()
  end
end