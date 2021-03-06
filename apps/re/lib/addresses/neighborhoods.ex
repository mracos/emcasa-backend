defmodule Re.Addresses.Neighborhoods do
  @moduledoc """
  Context for neighborhoods.
  """

  import Ecto.Query

  alias Re.{
    Address,
    Addresses.District,
    Listing,
    Repo,
    Slugs
  }

  @all_query from(
               a in Address,
               join: l in Listing,
               where: l.address_id == a.id and l.status == "active",
               select: a.neighborhood,
               distinct: a.neighborhood
             )

  @covered_for_show ["partially_covered", "covered"]

  def all, do: Repo.all(@all_query)

  def get_description(address) do
    case Repo.get_by(District,
           state_slug: address.state_slug,
           city_slug: address.city_slug,
           name_slug: address.neighborhood_slug
         ) do
      nil -> {:error, :not_found}
      description -> {:ok, description}
    end
  end

  def districts,
    do:
      Repo.all(from(d in District, where: d.status in @covered_for_show, order_by: d.sort_order))

  def districts_by_uuids(uuids \\ []) do
    Repo.all(from(d in District, where: d.uuid in ^uuids))
  end

  def get_district(params) do
    case Repo.get_by(District, params) do
      nil -> {:error, :not_found}
      district -> {:ok, district}
    end
  end

  @doc """
  Temporary mapping to find nearby neighborhood
  """
  def nearby("Botafogo"), do: "Humaitá"
  def nearby("Copacabana"), do: "Ipanema"
  def nearby("Flamengo"), do: "Laranjeiras"
  def nearby("Gávea"), do: "Leblon"
  def nearby("Humaitá"), do: "Botafogo"
  def nearby("Ipanema"), do: "Copacabana"
  def nearby("Itanhangá"), do: "São Conrado"
  def nearby("Jardim Botânico"), do: "Lagoa"
  def nearby("Lagoa"), do: "Humaitá"
  def nearby("Laranjeiras"), do: "Flamengo"
  def nearby("Leblon"), do: "Gávea"
  def nearby("São Conrado"), do: "Itanhangá"

  defp do_is_covered(neighborhood) do
    case Repo.get_by(District,
           name_slug: neighborhood.neighborhood_slug,
           city_slug: neighborhood.city_slug,
           state_slug: neighborhood.state_slug,
           status: "covered"
         ) do
      nil -> false
      _district -> true
    end
  end

  def is_covered(%Address{} = address), do: do_is_covered(address)

  def is_covered(neighborhood) do
    neighborhood
    |> sluggify_attributes()
    |> do_is_covered()
  end

  defp sluggify_attributes(neighborhood) do
    neighborhood
    |> Map.put(:city_slug, Slugs.sluggify(neighborhood.city))
    |> Map.put(:neighborhood_slug, Slugs.sluggify(neighborhood.neighborhood))
    |> Map.put(:state_slug, Slugs.sluggify(neighborhood.state))
  end
end
