defmodule ReIntegrations.TestHTTP do
  @moduledoc false

  def get(%URI{path: "/buildings/666"}, _) do
    {:ok, %{body: "{\"test\": \"building_payload\"}"}}
  end

  def get(%URI{path: "/buildings/666/images"}, _) do
    {:ok, %{body: "{\"test\": \"images_payload\"}"}}
  end

  def get(%URI{path: "/buildings/666/typologies"}, _) do
    {:ok, %{body: "{\"test\": \"typologies_payload\"}"}}
  end

  def get(%URI{path: "/buildings/1/typologies/1/units"}, _) do
    {:ok, %{body: "{\"units\": []}"}}
  end

  def get(%URI{path: "/buildings/1/typologies/2/units"}, _) do
    {:ok, %{body: "{\"units\": []}"}}
  end

  def get(%URI{path: "/simulator"}, [], _opts),
    do: {:ok, %{body: "{\"cem\":\"10,8%\",\"cet\":\"11,3%\"}"}}

  def post(%URI{path: "/priceteller"}, _, [
        {"Content-Type", "application/json"},
        {"X-Api-Key", "mahtoken"}
      ]),
      do:
        {:ok,
         %{
           body:
             "{" <>
               "\"listing_price\":632868.63," <>
               "\"listing_price_rounded\":635000.0," <>
               "\"sale_price\":575910.45," <>
               "\"sale_price_rounded\":575000.0}"
         }}

  def post(%URI{path: "/v1/vrp-long"}, _body, _opts),
    do: {:ok, %{body: "{\"job_id\": \"100\"}"}}

  def get(%URI{path: "/jobs/INVALID_JOB_ID"}, _opts),
    do: {:ok, %{status_code: 404}}

  def get(%URI{path: "/jobs/FINISHED_JOB_ID"}, _opts),
    do: {:ok, %{status_code: 200, body: "{\"status\": \"finished\", \"output\": {}}"}}

  def get(%URI{path: "/jobs/PENDING_JOB_ID"}, _opts),
    do: {:ok, %{status_code: 200, body: "{\"status\": \"pending\"}"}}

  def get(%URI{path: "/jobs/FAILED_JOB_ID"}, _opts),
    do: {:ok, %{status_code: 412, body: "{\"status\": \"error\", \"output\": \"error message\"}"}}
end
