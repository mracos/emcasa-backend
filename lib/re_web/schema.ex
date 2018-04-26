defmodule ReWeb.Schema do
  @moduledoc """
  Module for defining graphQL schemas
  """
  use Absinthe.Schema
  import_types ReWeb.Schema.ListingTypes
  import_types ReWeb.Schema.UserTypes

  alias ReWeb.Resolvers

  query do
    @desc "Get favorited listings"
    field :favorited_listings, list_of(:listing) do
      resolve &Resolvers.Users.favorited/2
    end

    @desc "Get favorited users"
    field :show_favorited_users, list_of(:user) do
      arg :id, non_null(:id)
      resolve &Resolvers.Favorites.favorited_users/2
    end

    @desc "List user messages, optionally by listing"
    field :listing_user_messages, list_of(:message) do
      arg :listing_id, :id

      resolve &Resolvers.Messages.get/2
    end
  end

  mutation do
    @desc "Activate listing"
    field :activate_listing, type: :listing do
      arg :id, non_null(:id)

      resolve &Resolvers.Listings.activate/2
    end

    @desc "Deactivate listing"
    field :deactivate_listing, type: :listing do
      arg :id, non_null(:id)

      resolve &Resolvers.Listings.deactivate/2
    end

    @desc "Favorite listing"
    field :favorite_listing, type: :listing_user do
      arg :id, non_null(:id)

      resolve &Resolvers.Favorites.favorite/2
    end

    @desc "Unfavorite listing"
    field :unfavorite_listing, type: :listing_user do
      arg :id, non_null(:id)

      resolve &Resolvers.Favorites.unfavorite/2
    end

    @desc "Tour visualization"
    field :tour_visualized, type: :listing do
      arg :id, non_null(:id)

      resolve &Resolvers.ListingStats.tour_visualized/2
    end

    @desc "Send message"
    field :send_message, type: :message do
      arg :receiver_id, non_null(:id)
      arg :listing_id, :id

      arg :message, :string

      resolve &Resolvers.Messages.send/2
    end
  end

  subscription do
    @desc "Subscribe to your messages"
    field :message_sent, :message do
      config(fn _args, %{context: %{current_user: current_user}} ->
        case current_user do
          %{id: receiver_id} -> {:ok, topic: receiver_id}
          _ -> {:error, :unauthenticated}
        end
      end)

      trigger :send_message,
        topic: fn message ->
          message.receiver_id
        end
    end
  end
end