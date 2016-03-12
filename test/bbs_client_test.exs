defmodule BBSClientTest do
  use ExUnit.Case
  doctest BBSMqClient

  @bbs_address "http://127.0.0.1:8889"
  @guid "distributed-lock_scheduler_default"
  @domain "scheduler"

  def loop(times, f) do
    cond do
      times > 0 ->
        f.(times)
        loop(times - 1, f)
      true ->
          IO.puts "loop complete"
    end
  end

  setup do
    {:ok, pid} = BBSMqClient.start_link
    {:ok, %{pid: pid}}
  end

  test "BBSClient ping", %{pid: pid}  do
    loop(10, fn(i) -> BBSMqClient.actual_lrp_groups(pid, fn(payload, meta_data) ->
                              payload.actual_lrp_groups
                              |> Enum.map(fn(actual_lrp_group) ->
                                net_info = actual_lrp_group.instance.actual_lrp_net_info
                                Enum.map(net_info.ports, &(net_info.address <> ":" <> Integer.to_string(&1.host_port) <> "\n"))
                              end)
                              |> IO.puts
                            end)
              end)
    receive do
      {:msg} ->
    end
  end

  # test "ActualLRP list" do
  #   {:ok, res} = BBSClient.ActualLRP.list @bbs_address
  #   actual_lrps = BBSModels.ActualLRPGroupsResponse.decode(res).actual_lrp_groups
  #   assert length(actual_lrps) > 0
  # end
  #
  # test "ActualLRP list_by_process_guid" do
  #   {:ok, res} = BBSClient.ActualLRP.list_by_process_guid @bbs_address, process_guid: @guid
  #   actual_lrps = BBSModels.ActualLRPGroupsResponse.decode(res).actual_lrp_groups
  #   assert length(actual_lrps) > 0
  #   assert hd(actual_lrps).instance.actual_lrp_key.process_guid == @guid
  # end
  #
  # test "ActualLRP get_by_process_guid_and_index" do
  #   {:ok, res} = BBSClient.ActualLRP.get_by_process_guid_and_index @bbs_address, process_guid: @guid, index: 0
  #   actual_lrp = BBSModels.ActualLRPGroupResponse.decode(res).actual_lrp_group
  #   assert actual_lrp.instance.actual_lrp_key.process_guid == @guid
  # end
  #
  # test "DesiredLRP list" do
  #   {:ok, res} = BBSClient.DesiredLRP.list @bbs_address
  #   desired_lrps = BBSModels.DesiredLRPsResponse.decode(res).desired_lrps
  #   assert length(desired_lrps) > 0
  # end
  #
  # test "DesiredLRP get_by_process_guid" do
  #   {:ok, res} = BBSClient.DesiredLRP.get_by_process_guid @bbs_address, process_guid: @guid
  #   desired_lrp = BBSModels.DesiredLRPResponse.decode(res).desired_lrp
  #   assert desired_lrp.process_guid == @guid
  # end
  #
  # test "DesiredLRP scheduling_infos_list" do
  #   {:ok, res} = BBSClient.DesiredLRP.scheduling_infos_list @bbs_address, domain: @domain
  #   desired_lrp_scheduling_infos = BBSModels.DesiredLRPSchedulingInfosResponse.decode(res).desired_lrp_scheduling_infos
  #   assert length(desired_lrp_scheduling_infos) > 0
  #   assert Enum.any?(desired_lrp_scheduling_infos, &(&1.desired_lrp_key.domain == @domain))
  # end
end
