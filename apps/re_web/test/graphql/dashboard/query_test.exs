defmodule ReWeb.GraphQL.Dashboard.QueryTest do
  use ReWeb.ConnCase

  import Re.Factory

  alias ReWeb.AbsintheHelpers

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    admin_user = insert(:user, email: "admin@email.com", role: "admin")
    user_user = insert(:user, email: "user@email.com", role: "user")

    {:ok,
     unauthenticated_conn: conn,
     admin_conn: login_as(conn, admin_user),
     user_conn: login_as(conn, user_user)}
  end

  describe "dashboard" do
    test "admin should query dashboard", %{admin_conn: conn} do
      insert(:listing, status: "inactive", is_release: false)

      insert(
        :listing,
        listings_favorites: [build(:listings_favorites)],
        maintenance_fee: 123.321,
        property_tax: 321.123,
        matterport_code: "asdsa",
        area: 50,
        is_release: false
      )

      insert(
        :listing,
        maintenance_fee: nil,
        property_tax: nil,
        matterport_code: nil,
        area: nil,
        is_release: false
      )

      query = """
        query Dashboard {
          dashboard {
            activeListingCount
            favoriteCount
            visualizationCount
            tourVisualizationCount
            maintenanceFeeCount
            propertyTaxCount
            tourCount
            areaCount
          }
        }
      """

      conn = post(conn, "/graphql_api", AbsintheHelpers.query_wrapper(query))

      assert %{
               "activeListingCount" => 2,
               "favoriteCount" => 1,
               "visualizationCount" => 0,
               "tourVisualizationCount" => 0,
               "maintenanceFeeCount" => 1,
               "propertyTaxCount" => 1,
               "tourCount" => 1,
               "areaCount" => 1
             } == json_response(conn, 200)["data"]["dashboard"]
    end

    test "user should not query dashboard", %{user_conn: conn} do
      query = """
        query Dashboard {
          dashboard {
            activeListingCount
            favoriteCount
            visualizationCount
            tourVisualizationCount
            maintenanceFeeCount
            propertyTaxCount
            tourCount
            areaCount
          }
        }
      """

      conn = post(conn, "/graphql_api", AbsintheHelpers.query_wrapper(query))

      assert [%{"message" => "Forbidden", "code" => 403}] = json_response(conn, 200)["errors"]
    end

    test "anonymous should not query dashboard", %{unauthenticated_conn: conn} do
      query = """
        query Dashboard {
          dashboard {
            activeListingCount
            favoriteCount
            visualizationCount
            tourVisualizationCount
            maintenanceFeeCount
            propertyTaxCount
            tourCount
            areaCount
          }
        }
      """

      conn = post(conn, "/graphql_api", AbsintheHelpers.query_wrapper(query))

      assert [%{"message" => "Unauthorized", "code" => 401}] = json_response(conn, 200)["errors"]
    end
  end

  describe "active_listing_count" do
    test "should return the total number of active listings", %{admin_conn: conn} do
      insert_list(5, :listing, status: "active")

      query = """
        query Dashboard {
          dashboard {
            activeListingCount
          }
        }
      """

      conn = post(conn, "/graphql_api", AbsintheHelpers.query_wrapper(query))

      assert %{
               "activeListingCount" => 5
             } == json_response(conn, 200)["data"]["dashboard"]
    end

    test "should apply listing filters to active listings count", %{admin_conn: conn} do
      insert(:listing, status: "active", is_release: false, is_exportable: true)
      insert(:listing, status: "active", is_release: true, is_exportable: false)
      insert(:listing, status: "active", is_release: true, is_exportable: true)

      query = """
        query Dashboard($filters: ListingFilterInput) {
          dashboard {
            activeListingCount(filters: $filters)
          }
        }
      """

      variables = %{
        "filters" => %{
          "isExportable" => true,
          "isRelease" => true
        }
      }

      conn = post(conn, "/graphql_api", AbsintheHelpers.query_wrapper(query, variables))

      assert %{
               "activeListingCount" => 1
             } == json_response(conn, 200)["data"]["dashboard"]
    end
  end

  describe "listings" do
    test "query all listings", %{admin_conn: conn} do
      variables = %{
        "pagination" => %{
          "page" => 1,
          "pageSize" => 2
        },
        "filters" => %{
          "maxPrice" => 2_000_000
        },
        "orderBy" => [
          %{
            "field" => "ID",
            "type" => "ASC"
          }
        ]
      }

      insert_list(4, :listing, price: 2_500_000)
      [l1, l2 | _] = insert_list(6, :listing, price: 1_500_000)

      query = """
        query MyQuery(
          $pagination: ListingPaginationAdminInput,
          $filters: ListingFilterInput,
          $orderBy: OrderBy
        ) {
          Dashboard {
            listings(pagination: $pagination, filters: $filters, orderBy: $orderBy) {
              entries {
                id
              }
              pageNumber
              pageSize
              totalPages
              totalEntries
            }
          }
        }
      """

      conn = post(conn, "/graphql_api", AbsintheHelpers.query_wrapper(query, variables))

      query_response = json_response(conn, 200)["data"]["Dashboard"]["listings"]

      assert [%{"id" => to_string(l1.id)}, %{"id" => to_string(l2.id)}] ==
               query_response["entries"]

      assert 1 == query_response["pageNumber"]
      assert 2 == query_response["pageSize"]
      assert 3 == query_response["totalPages"]
      assert 6 == query_response["totalEntries"]
    end
  end
end
