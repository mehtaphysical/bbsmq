bbs_address = "http://127.0.0.1:8889"

# {:ok, pid} = BbsMq.start_link
# BbsEventListener.listen pid, bbs_address <> "/v1/actual_lrp_events"
# BbsEventListener.listen pid, bbs_address <> "/v1/desired_lrp_events"
# BbsEventListener.listen pid, bbs_address <> "/v1/task_events"

HTTPoison.start
desire_lrp = Bbs
{:ok, encoded_desired_scheduling_infos} = BbsDesiredLrp.scheduling_infos_list bbs_address, "settings"
desired_scheduling_infos= BBSModels.DesiredLRPSchedulingInfosResponse.decode(encoded_desired_scheduling_infos)
Enum.each(desired_scheduling_infos.desired_lrp_scheduling_infos, &(IO.puts &1.desired_lrp_key.process_guid))

receive do
  {:msg} -> IO.puts "hi"
end
