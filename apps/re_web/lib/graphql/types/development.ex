defmodule ReWeb.Types.Development do
  @moduledoc """
  GraphQL types for developments
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias ReWeb.Resolvers

  object :development do
    field :id, :id
    field :name, :string
    field :title, :string
    field :phase, :string
    field :builder, :string
    field :description, :string

    field :address, :address,
      resolve: dataloader(Re.Addresses, &Resolvers.Addresses.per_development/3)

    field :images, list_of(:image) do
      arg :is_active, :boolean
      arg :limit, :integer

      resolve &Resolvers.Images.per_development/3
    end
  end

  input_object :development_input do
    field :name, :string
    field :title, :string
    field :phase, :string
    field :builder, :string
    field :description, :string

    field :address_id, :id
  end

  object :development_queries do
    @desc "Developments index"
    field :developments, list_of(:development) do
      resolve &Resolvers.Developments.index/2
    end

    @desc "Show development"
    field :development, :development do
      arg :id, non_null(:id)

      resolve &Resolvers.Developments.show/2
    end
  end

  object :development_mutations do
    @desc "Insert development"
    field :insert_development, type: :development do
      arg :input, non_null(:development_input)

      resolve &Resolvers.Developments.insert/2
    end

    @desc "Update development"
    field :update_development, type: :development do
      arg :id, non_null(:id)
      arg :input, non_null(:development_input)

      resolve &Resolvers.Developments.update/2
    end
  end
end