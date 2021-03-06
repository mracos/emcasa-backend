defmodule Re.Unit do
  @moduledoc """
  Model for real estate commom properties, each real estate can have one
  or more units.
  """
  use Ecto.Schema

  import Ecto.Changeset
  alias Re.Listing

  @primary_key {:uuid, :binary_id, autogenerate: false}

  schema "units" do
    field :complement, :string
    field :price, :integer
    field :property_tax, :float
    field :maintenance_fee, :float
    field :floor, :string
    field :rooms, :integer
    field :bathrooms, :integer
    field :restrooms, :integer
    field :area, :integer
    field :garage_spots, :integer, default: 0
    field :garage_type, :string
    field :suites, :integer
    field :dependencies, :integer
    field :balconies, :integer
    field :status, :string
    field :matterport_code, :string
    field :is_exportable, :boolean, default: false

    belongs_to :development, Re.Development,
      references: :uuid,
      foreign_key: :development_uuid,
      type: Ecto.UUID

    belongs_to :listing, Re.Listing

    timestamps()
  end

  @garage_types ~w(contract condominium)
  @statuses ~w(active inactive)

  @required ~w(price rooms bathrooms area garage_spots suites development_uuid status)a
  @optional ~w(complement floor property_tax maintenance_fee balconies restrooms garage_type
              dependencies listing_id matterport_code is_exportable)a

  @attributes @required ++ @optional

  def changeset(struct, params) do
    struct
    |> cast(params, @attributes)
    |> validate_required(@required)
    |> validate_attributes()
    |> validate_number(
      :price,
      greater_than_or_equal_to: Listing.price_lower_limit(),
      less_than_or_equal_to: Listing.price_upper_limit()
    )
    |> validate_inclusion(:garage_type, @garage_types)
    |> validate_inclusion(:status, @statuses)
    |> Re.ChangesetHelper.generate_uuid()
  end

  @non_negative_attributes ~w(property_tax maintenance_fee
                              bathrooms garage_spots suites
                              dependencies balconies restrooms)a

  defp validate_attributes(changeset) do
    Enum.reduce(@non_negative_attributes, changeset, &non_negative/2)
  end

  defp non_negative(attr, changeset) do
    validate_number(changeset, attr, greater_than_or_equal_to: 0)
  end
end
