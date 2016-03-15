defmodule BBSClientTest do
  use ExUnit.Case
  doctest BBSMqClient

  @bbs_address "http://127.0.0.1:8889"
  @guid "distributed-lock_scheduler_default"
  @domain "scheduler"

  defmodule MyEventHandler do
    use BBSMqClient.EventHandler, routing_key: "actual_lrp.*"

    def handle_event({"actual_lrp.created", %{channel: channel, payload: payload, meta_data: meta_data}}) do
      IO.puts "actual_lrp.created"
      net_info = payload.actual_lrp_group.instance.actual_lrp_net_info
      address = net_info.address
      Enum.each(net_info.ports, fn(port) ->
        IO.puts(address <> Integer.to_string(port.host_port))
      end)
      AMQP.Basic.ack channel, meta_data.delivery_tag
    end

    def handle_event({"actual_lrp.changed", %{channel: channel, payload: payload, meta_data: meta_data}}) do
      IO.puts "actual_lrp.changed"
      net_info = payload.after.instance.actual_lrp_net_info
      address = net_info.address
      IO.puts payload.after.instance.state
      Enum.each(net_info.ports, fn(port) ->
        IO.puts(address <> ":" <> Integer.to_string(port.host_port))
        IO.puts(address <> ":" <> Integer.to_string(port.container_port))
      end)
      encoded_payload = BBSModels.DesiredLRPByProcessGuidRequest.new([process_guid: "distributed-lock_community_default"])
      |> BBSModels.DesiredLRPByProcessGuidRequest.encode
      BBSMqClient.desired_lrp_by_process_guid(:bbsmq_manager, encoded_payload, fn(desired_lrp_by_process_guid_repones, meta_data) ->
        IO.puts desired_lrp_by_process_guid_repones.desired_lrp.routes
        desired_lrp_by_process_guid_repones.desired_lrp.routes
        # |> String.replace(~r/\s*x\s*/, "")
        |> String.replace("tcp-router", "tcp_router")
        #|> BBSModels.Routes.decode
        |> IO.puts
      end)
      AMQP.Basic.ack channel, meta_data.delivery_tag
    end

    def handle_event({"actual_lrp.removed", %{channel: channel, payload: payload, meta_data: meta_data}}) do
      IO.puts "actual_lrp.removed"
      net_info = payload.actual_lrp_group.instance.actual_lrp_net_info
      address = net_info.address
      Enum.each(net_info.ports, fn(port) ->
        IO.puts(address <> Integer.to_string(port.host_port))
      end)
      AMQP.Basic.ack channel, meta_data.delivery_tag
    end
  end

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
    {:ok, pid} = BBSMqClient.start_link("bbs_test")
    {:ok, %{pid: pid}}
  end

  @tag timeout: :infinity
  test "BBSClient ping", %{pid: pid}  do
    encoded_payload = BBSModels.DesiredLRPsRequest.new([domain: "lmpp"])
    |> BBSModels.DesiredLRPsRequest.encode

    {:ok, payload, meta_data} = BBSMqClient.desired_lrps(:bbsmq_manager, encoded_payload)
    Enum.each(payload.desired_lrps, fn(desired_lrp) ->
      unless is_nil(desired_lrp.routes) do
        routes = desired_lrp.routes
        |> String.split("\n")
        |> Enum.map(&(String.lstrip(&1)))
        |> Enum.filter(&(String.starts_with?(&1, "tcp-router")))
        |> Enum.join
        |> String.replace(~r/^tcp-router.*\[/, "[")
        |> String.replace(~r/\]$/, "]")

        if String.length(routes) > 0 do
          IO.puts routes
          Poison.Parser.parse!(routes, keys: :atoms)
          |> Enum.each(&(IO.puts &1.external_port))
        end
      end
    end)

    # actual_lrp_req = BBSModels.ActualLRPGroupsRequest.new([domain: "lmpp"])
    # |> BBSModels.ActualLRPGroupsRequest.encode
    #
    # BBSMqClient.actual_lrp_groups(:bbsmq_manager, actual_lrp_req, fn(payload, meta_data) ->
    #   payload.actual_lrp_groups
    #   |> Enum.map(&(&1.instance.actual_lrp_net_info.ports))
    #   |> List.flatten
    #   |> Enum.each(&(IO.puts &1.host_port))
    # end)
    #MyEventHandler.start_link("bbs_test_queue")

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
