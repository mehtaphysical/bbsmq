defmodule ActualLRPClient do
  defmodule List do
    @list_path "/v1/actual_lrp_groups/list"
    @process_guid_list_path "/v1/actual_lrp_groups/list_by_process_guid"

    def list(bbs_address, filter_map \\ [])

    def list(bbs_address, []) do
      list(bbs_address, domain: "", cell_id: "")
    end

    def list(bbs_address, actual_lrp_groups_request) do
      url = bbs_address <> @list_path
      BBSHTTPClient.protobuf_request(url,BBSModels.ActualLRPGroupsRequest, actual_lrp_groups_request)
    end

    def by_process_guid_path(bbs_address, actual_lrp_groups_by_process_guid_request) do
      url = bbs_address <> @process_guid_list_path
      BBSHTTPClient.protobuf_request(url, BBSModels.ActualLRPGroupsByProcessGuidRequest, actual_lrp_groups_by_process_guid_request)
    end
  end
end
