defmodule Re.OwnerContacts do
  @moduledoc """
  Context for owner contacts.
  """
  @behaviour Bodyguard.Policy

  alias Re.{
    OwnerContact,
    Repo
  }

  defdelegate authorize(action, user, params), to: __MODULE__.Policy

  def data(params), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(_query, _args), do: OwnerContact

  def all, do: Repo.all(OwnerContact)

  def get(uuid) do
    OwnerContact
    |> Repo.get(uuid)
    |> get_response()
  end

  def get_by_phone(phone) do
    OwnerContact
    |> Repo.get_by(phone: phone)
    |> get_response()
  end

  defp get_response(nil), do: {:error, :not_found}
  defp get_response(contact), do: {:ok, contact}

  @replace_fields ~w(name email additional_phones additional_emails updated_at)a

  def upsert(params) do
    upsert(%OwnerContact{}, params)
  end

  def upsert(struct, params) do
    struct
    |> Map.put(:uuid, nil)
    |> OwnerContact.changeset(params)
    |> Repo.insert(
      returning: true,
      on_conflict: {:replace, @replace_fields},
      conflict_target: [:name_slug, :phone]
    )
  end
end
