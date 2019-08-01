defmodule ReIntegrations.Salesforce.Payload.OpportunityTest do
  use ReIntegrations.ModelCase

  alias ReIntegrations.Salesforce.Payload

  @payload %{
    "Id" => "0x01",
    "AccountId" => "0x02",
    "OwnerId" => "0x02",
    "Dados_do_Imovel_para_Venda__c" => "address string",
    "Bairro__c" => "neighborhood",
    "Horario_Fixo_para_o_Tour__c" => "20:00:00",
    "Periodo_Disponibilidade_Tour__c" => "Manhã"
  }

  describe "build/1" do
    test "builds payload struct from salesforce response" do
      assert {:ok, %Payload.Opportunity{} = opportunity} = Payload.Opportunity.build(@payload)
      assert opportunity.id == @payload["Id"]
      assert opportunity.account_id == @payload["AccountId"]
      assert opportunity.owner_id == @payload["OwnerId"]
      assert opportunity.address == @payload["Dados_do_Imovel_para_Venda__c"]
      assert opportunity.neighborhood == @payload["Bairro__c"]
      assert opportunity.tour_strict_time == ~T[20:00:00Z]
      assert opportunity.tour_period == :morning
    end
  end

  describe "visit_start_window/1" do
    test "returns exact time when tour period is strict" do
      assert %{start: ~T[20:00:00Z], end: ~T[20:00:00Z]} =
               Payload.Opportunity.visit_start_window(%{
                 tour_strict_time: ~T[20:00:00Z],
                 tour_period: :strict
               })
    end

    test "returns time range from tour period" do
      assert %{start: ~T[09:00:00Z], end: ~T[12:00:00Z]} =
               Payload.Opportunity.visit_start_window(%{tour_period: :morning})

      assert %{start: ~T[12:00:00Z], end: ~T[18:00:00Z]} =
               Payload.Opportunity.visit_start_window(%{tour_period: :afternoon})

      assert %{start: ~T[09:00:00Z], end: ~T[18:00:00Z]} =
               Payload.Opportunity.visit_start_window(%{tour_period: :flexible})
    end

    test "returns default time range when not specified" do
      assert %{start: ~T[09:00:00Z], end: ~T[18:00:00Z]} =
               Payload.Opportunity.visit_start_window(%{})
    end
  end
end