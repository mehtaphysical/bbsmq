defmodule BBSClientTest do
  use ExUnit.Case
  doctest BBSClient

  HTTPoison.start

  @bbs_address "http://127.0.0.1:8889"
  @guid "distributed-lock_scheduler_default"
  @domain "scheduler"

  test "BBSClient ping" do
    {:ok, res} = BBSClient.ping @bbs_address
    assert BBSModels.PingResponse.decode(res).available
  end

  test "ActualLRP List" do
    {:ok, res} = ActualLRPClient.List.list @bbs_address
    actual_lrps = BBSModels.ActualLRPGroupsResponse.decode(res).actual_lrp_groups
    assert length(actual_lrps) > 0
  end

  test "DesiredLRP list" do
    {:ok, res} = BBSClient.DesiredLRP.list @bbs_address
    desired_lrps = BBSModels.DesiredLRPsResponse.decode(res).desired_lrps
    assert length(desired_lrps) > 0
  end

  test "DesiredLRP get_by_process_guid" do
    {:ok, res} = BBSClient.DesiredLRP.get_by_process_guid @bbs_address, process_guid: @guid
    desired_lrp = BBSModels.DesiredLRPResponse.decode(res).desired_lrp
    assert desired_lrp.process_guid == @guid
  end

  test "DesiredLRP scheduling_infos_list" do
    {:ok, res} = BBSClient.DesiredLRP.scheduling_infos_list @bbs_address, domain: @domain
    desired_lrp_scheduling_infos = BBSModels.DesiredLRPSchedulingInfosResponse.decode(res).desired_lrp_scheduling_infos
    assert length(desired_lrp_scheduling_infos) > 0
    assert Enum.any?(desired_lrp_scheduling_infos, &(&1.desired_lrp_key.domain == @domain))
  end
end
