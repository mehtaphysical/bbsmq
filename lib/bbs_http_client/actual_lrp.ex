defmodule ActualLRPClient do
  defmacro __using__(_) do
    quote do
      @list_path "/v1/actual_lrp_groups/list"
      @list_by_process_guid_path "/v1/actual_lrp_groups/list_by_process_guid"
      @get_by_process_guid_and_index_path "/v1/actual_lrp_groups/get_by_process_guid_and_index"

      def list(bbs_address, actual_lrp_groups_request \\ []) do
        url = bbs_address <> @list_path
        BBSHTTPClient.protobuf_request url, BBSModels.ActualLRPGroupsRequest, actual_lrp_groups_request
      end

      def list_by_process_guid(bbs_address, actual_lrp_groups_by_process_guid_request) do
        url = bbs_address <> @list_by_process_guid_path
        BBSHTTPClient.protobuf_request url, BBSModels.ActualLRPGroupsByProcessGuidRequest, actual_lrp_groups_by_process_guid_request
      end

      def get_by_process_guid_and_index(bbs_address, actual_lrp_groups_by_process_guid_and_index_request) do
        url = bbs_address <> @get_by_process_guid_and_index_path
        BBSHTTPClient.protobuf_request url, BBSModels.ActualLRPGroupByProcessGuidAndIndexRequest, actual_lrp_groups_by_process_guid_and_index_request
      end
    end
  end
end
