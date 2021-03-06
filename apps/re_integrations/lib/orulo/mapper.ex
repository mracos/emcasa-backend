defmodule ReIntegrations.Orulo.Mapper do
  @moduledoc """
  Module to map external structures into persistable internal structures.
  """
  alias ReIntegrations.{
    Orulo.BuildingPayload
  }

  @development_attributes ~w(name description developer number_of_floors apts_per_floor status id)
  def building_payload_into_development_params(%BuildingPayload{} = %{payload: payload}) do
    payload
    |> Map.take(@development_attributes)
    |> Enum.reduce(%{}, &convert_development_attribute(&1, &2))
  end

  defp convert_development_attribute({"name", name}, acc), do: Map.put(acc, :name, name)

  defp convert_development_attribute({"description", description}, acc),
    do: Map.put(acc, :description, description)

  defp convert_development_attribute({"developer", %{"name" => name}}, acc) do
    Map.put(acc, :builder, name)
  end

  defp convert_development_attribute({"number_of_floors", floor_count}, acc) do
    Map.put(acc, :floor_count, floor_count)
  end

  defp convert_development_attribute({"apts_per_floor", units_per_floor}, acc) do
    Map.put(acc, :units_per_floor, units_per_floor)
  end

  @phase_map %{
    "Em construção" => "building",
    "Pronto novo" => "delivered",
    "Pronto usado" => "delivered"
  }

  defp convert_development_attribute({"status", status}, acc) do
    phase = Map.get(@phase_map, status)
    Map.put(acc, :phase, phase)
  end

  defp convert_development_attribute({"id", orulo_id}, acc) do
    Map.put(acc, :orulo_id, orulo_id)
  end

  defp convert_development_attribute(_, acc), do: acc

  @address_attributes ~w(street area city state zip_code latitude longitude number)
  def building_payload_into_address_params(
        %BuildingPayload{} = %{payload: %{"address" => address}}
      ) do
    address
    |> Map.take(@address_attributes)
    |> Enum.reduce(%{}, &convert_address_attribute(&1, &2))
  end

  defp convert_address_attribute({"street", street}, acc) do
    Map.put(acc, :street, street)
  end

  defp convert_address_attribute({"area", neighborhood}, acc) do
    Map.put(acc, :neighborhood, neighborhood)
  end

  defp convert_address_attribute({"city", city}, acc) do
    Map.put(acc, :city, city)
  end

  defp convert_address_attribute({"state", state}, acc) do
    Map.put(acc, :state, state)
  end

  defp convert_address_attribute({"zip_code", postal_code}, acc) do
    Map.put(acc, :postal_code, postal_code)
  end

  defp convert_address_attribute({"latitude", lat}, acc) do
    Map.put(acc, :lat, lat)
  end

  defp convert_address_attribute({"longitude", lng}, acc) do
    Map.put(acc, :lng, lng)
  end

  defp convert_address_attribute({"number", number}, acc) do
    Map.put(acc, :street_number, Integer.to_string(number))
  end

  defp convert_address_attribute(_, acc), do: acc
end
