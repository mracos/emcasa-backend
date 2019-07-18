defmodule ReIntegrations.Google.CalendarsTest do
  @moduledoc false

  use ReIntegrations.ModelCase

  alias GoogleApi.Calendar.V3.Model

  alias ReIntegrations.Google.Calendars

  import Tesla.Mock

  import Re.Factory

  @calendar_id "calendar123"

  @calendar_response """
  {
    "id": "#{@calendar_id}",
    "kind": "calendar#calendar"
  }
  """

  @acl_response """
  {
    "kind": "calendar#acl"
  }
  """

  @event_response """
  {
    "kind": "calendar#event"
  }
  """

  @event_list_response """
  {
    "items": [{"kind": "calendar#event"}]
  }
  """

  describe "insert/2" do
    setup do
      mock(fn
        %{method: :post, url: "https://www.googleapis.com/calendar/v3/calendars"} ->
          %Tesla.Env{status: 200, body: @calendar_response}

        %{
          method: :post,
          url: "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/acl"
        } ->
          %Tesla.Env{status: 200, body: @acl_response}
      end)

      :ok
    end

    test "creates a google calendar and inserts it to the database" do
      assert {:ok, calendar = %Re.GoogleCalendars.Calendar{}} =
               Calendars.insert(%{
                 shift_start: "10:00",
                 shift_end: "12:00"
               })

      assert "10:00" == calendar.shift_start
      assert "12:00" == calendar.shift_end
    end
  end

  describe "insert_event/2" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/events"
        } ->
          %Tesla.Env{status: 200, body: @event_response}
      end)

      :ok
    end

    test "inserts an event into a google calendar" do
      calendar = insert(:calendar, external_id: @calendar_id)
      {:ok, start_time} = DateTime.now("Etc/UTC")

      assert {:ok, %Model.Event{}} =
               Calendars.insert_event(calendar, summary: "test", start: start_time)
    end
  end

  describe "get_events/2" do
    setup do
      mock(fn
        %{
          method: :get,
          url: "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/events"
        } ->
          %Tesla.Env{status: 200, body: @event_list_response}
      end)

      :ok
    end

    test "inserts an event into a google calendar" do
      calendar = insert(:calendar, external_id: @calendar_id)
      assert {:ok, %Model.Events{}} = Calendars.get_events(calendar)
    end
  end
end
