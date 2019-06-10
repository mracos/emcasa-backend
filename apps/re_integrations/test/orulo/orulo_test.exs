defmodule ReIntegrations.OruloTest do
  @moduledoc false

  import ReIntegrations.Factory

  use ReIntegrations.ModelCase

  alias ReIntegrations.{
    Orulo,
    Orulo.JobQueue,
    Repo
  }

  alias Ecto.Multi

  describe "get_building_payload/2" do
    test "create o new job with to sync development" do
      assert {:ok, _} = Orulo.get_building_payload(100)
      assert Repo.one(JobQueue)
    end

    test "doesn't create a job if building payload already exists for orulo id" do
      insert(:building_payload, external_id: 100)
      assert {:error, _} = Orulo.get_building_payload(100)
      assert [] == Repo.all(JobQueue)
    end
  end

  describe "multi_building_payload_insert/2" do
    test "create new building" do
      params = %{external_id: 666, payload: %{test: "building_payload"}}

      assert {:ok, %{building: inserted_building}} =
               Orulo.multi_building_payload_insert(Multi.new(), params)

      assert inserted_building.uuid
      assert inserted_building.external_id == 666
      assert inserted_building.payload == %{test: "building_payload"}
    end

    test "enqueue a new parse job" do
      params = %{external_id: 666, payload: %{test: "building_payload"}}
      assert {:ok, _} = Orulo.multi_building_payload_insert(Multi.new(), params)
      assert Repo.one(JobQueue)
    end
  end

  describe "multi_images_payload_insert/2" do
    test "create new image payload" do
      params = %{external_id: 666, payload: %{test: "images_payload"}}

      assert {:ok, %{insert_images_payload: images_payload}} =
               Orulo.multi_images_payload_insert(Multi.new(), params)

      assert images_payload.uuid
      assert images_payload.external_id == 666
      assert images_payload.payload == %{test: "images_payload"}
    end

    test "enqueue a new parse images job" do
      params = %{external_id: 666, payload: %{test: "images_payload"}}
      assert {:ok, _} = Orulo.multi_images_payload_insert(Multi.new(), params)

      assert Repo.one(JobQueue)
    end
  end

  describe "building_already_synced?/2" do
    test "return false when payload does not exists" do
      insert(:building_payload, external_id: 1)
      refute Orulo.building_payload_synced?(2)
    end

    test "return true when payload does exists" do
      insert(:building_payload, external_id: 1)
      assert Orulo.building_payload_synced?(1)
    end
  end
end