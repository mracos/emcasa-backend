defmodule Re.Shortlists.Salesforce.Opportunity do
  @moduledoc """
  Module for validating and parse salesforce opportunity entity on shortlist context
  """
  alias Re.Slugs

  use Ecto.Schema

  import Ecto.Changeset

  import EctoEnum

  @primary_key {:id, :string, []}

  defenum(Schema,
    infrastructure: "Infraestrutura__c",
    type: "Tipo_do_Imovel__c",
    min_rooms: "Quantidade_Minima_de_Quartos__c",
    min_suites: "Quantidade_MInima_de_SuItes__c",
    min_bathrooms: "Quantidade_Minima_de_Banheiros__c",
    min_garage_spots: "Numero_Minimo_de_Vagas__c",
    min_area: "Area_Desejada__c",
    preference_floor: "Andar_de_Preferencia__c",
    elevators: "Necessita_Elevador__c",
    nearby_subway: "Proximidade_de_Metr__c",
    neighborhoods: "Bairros_de_Interesse__c",
    price_range: "Valor_M_ximo_para_Compra_2__c",
    maintenance_fee_range: "Valor_M_ximo_de_Condom_nio__c",
    lobby: "Portaria_2__c",
    user_name: "AccountName",
    owner_name: "OwnerName"
  )

  defenum(PreferenceFloor,
    high: "Alto",
    low: "Baixo"
  )

  schema "salesforce_opportunity" do
    field :infrastructure, {:array, :string}
    field :type, :string
    field :min_rooms, :integer
    field :min_suites, :integer
    field :min_bathrooms, :integer
    field :min_garage_spots, :integer
    field :min_area, :integer
    field :preference_floor, PreferenceFloor
    field :elevators, :boolean
    field :nearby_subway, :boolean
    field :neighborhoods, {:array, :string}
    field :price_range, {:array, :integer}
    field :maintenance_fee_range, {:array, :integer}
    field :lobby, :string
    field :user_name, :string
    field :owner_name, :string
  end

  @params ~w(infrastructure type min_rooms min_suites min_bathrooms min_garage_spots min_area
  preference_floor elevators nearby_subway neighborhoods price_range maintenance_fee_range lobby
  user_name owner_name)a

  @ignorable "Indiferente"

  def validate(params) do
    %__MODULE__{}
    |> changeset(params)
    |> case do
      %{valid?: true} = changeset -> {:ok, apply_changes(changeset)}
      changeset -> {:error, :invalid_input, params, changeset}
    end
  end

  def build(payload) do
    payload
    |> Map.take(Schema.__valid_values__())
    |> Enum.into(%{}, &build_field/1)
    |> validate()
  end

  defp build_field({field, @ignorable}) do
    with({:ok, key} <- Schema.cast(field), do: {key, nil})
  end

  defp build_field({"Valor_M_ximo_para_Compra_2__c" = field, value}) do
    price_range = build_price_range(value)
    with({:ok, key} <- Schema.cast(field), do: {key, price_range})
  end

  defp build_field({"Valor_M_ximo_de_Condom_nio__c" = field, value}) do
    maintenance_fee_range = build_maintenance_fee_range(value)
    with({:ok, key} <- Schema.cast(field), do: {key, maintenance_fee_range})
  end

  @multipick_field ~w(Infraestrutura__c Bairros_de_Interesse__c)
  defp build_field({field, value}) when field in @multipick_field do
    features =
      value
      |> String.split(";")
      |> Enum.reject(&(&1 == @ignorable))
      |> Enum.map(&Slugs.sluggify(&1))

    with({:ok, key} <- Schema.cast(field), do: {key, features})
  end

  defp build_field({"Area_Desejada__c" = field, value}) do
    min_area = build_min_area(value)
    with({:ok, key} <- Schema.cast(field), do: {key, min_area})
  end

  @sluggify_fields ~w(Portaria_2__c Tipo_do_Imovel__c)
  defp build_field({field, value}) when field in @sluggify_fields do
    new_value = Slugs.sluggify(value)
    with({:ok, key} <- Schema.cast(field), do: {key, new_value})
  end

  @boolean_field ~w(Necessita_Elevador__c Proximidade_de_Metr__c)
  @allowed_boolean_values ~w(Sim Não)

  @boolean_map %{
    "Sim" => true,
    "Não" => false
  }

  defp build_field({field, value})
       when field in @boolean_field and value in @allowed_boolean_values do
    boolean_value = Map.get(@boolean_map, value)

    with({:ok, key} <- Schema.cast(field), do: {key, boolean_value})
  end

  defp build_field({field, value}) do
    with({:ok, key} <- Schema.cast(field), do: {key, value})
  end

  @maintenance_fee %{
    "Até R$500" => [0, 500],
    "R$500 a R$800" => [500, 800],
    "R$800 a R$1.000" => [800, 1000],
    "R$1.000 a R$1.200" => [1_000, 1_200],
    "R$1.200 a R$1.500" => [1_200, 1_500],
    "R$1.500 a R$2.000" => [1_500, 2_000],
    "Acima de R$2.000" => [2_000, 20_000]
  }

  defp build_maintenance_fee_range(key), do: Map.get(@maintenance_fee, key)

  @min_area %{
    "A partir de 20m²" => 20,
    "A partir de 60m²" => 60,
    "A partir de 80m²" => 80,
    "A partir de 100m²" => 100,
    "A partir de 150m²" => 150
  }

  defp build_min_area(key), do: Map.get(@min_area, key)

  @price_range %{
    "Até R$400.000" => [0, 400_000],
    "Até R$500.000" => [0, 500_000],
    "Até R$600.000" => [0, 600_000],
    "Até R$700.000" => [0, 700_000],
    "Até R$800.000" => [0, 800_000],
    "Até R$900.000" => [0, 900_000],
    "Até R$1.000.000" => [0, 1_000_000],
    "Até R$1.500.000" => [0, 1_500_000],
    "De R$500.000 a R$750.000" => [500_000, 750_000],
    "De R$750.000 a R$1.000.000" => [750_000, 1_000_000],
    "De R$1.000.000 a R$1.500.000" => [1_000_000, 1_500_000],
    "Acima de R$2.000.000" => [2_000_000, 20_000_000]
  }

  defp build_price_range(key), do: Map.get(@price_range, key)

  defp changeset(struct, params), do: cast(struct, params, @params)
end
