defmodule DesiredLRPClient do
  defmacro __using__(_) do
    quote do
      @list_path "/v1/desired_lrps/list.r1"
      @by_process_guid_path "/v1/desired_lrps/get_by_process_guid.r1"
      @scheduling_infos_list_path "/v1/desired_lrp_scheduling_infos/list"

      @create_desired_lrp_path "/v1/desired_lrp/desire"
      @update_desired_lrp_path "/v1/desired_lrp/update"
      @remove_desired_lrp_path "/v1/desired_lrp/remove"

      def list(bbs_address) do
        BBSHTTPClient.request(bbs_address <> @list_path)
      end

      def get_by_process_guid(bbs_address, desired_lrp_by_process_guid_request) do
        url = bbs_address <> @by_process_guid_path
        BBSHTTPClient.protobuf_request url, BBSModels.DesiredLRPByProcessGuidRequest, desired_lrp_by_process_guid_request
      end

      def scheduling_infos_list(bbs_address, desired_lrps_request) do
        url = bbs_address <> @scheduling_infos_list_path
        BBSHTTPClient.protobuf_request url, BBSModels.DesiredLRPsRequest, desired_lrps_request
      end

      def create(bbs_address, desired_lrp_request) do
        url = bbs_address <> @create_desired_lrp_path
        BBSHTTPClient.protobuf_request url, BBSModels.DesireLRPRequest, desired_lrp_request
      end

      def update(bbs_address, update_desired_lrp_request) do
        url = bbs_address <> @update_desired_lrp_path
        BBSHTTPClient.protobuf_request url, BSModels.UpdateDesiredLRPRequest, update_desired_lrp_request
      end

      def remove(bbs_address, remove_desired_lrp_request) do
        url = bbs_address <> @remove_desired_lrp_path
        BBSHTTPClient.protobuf_request url, BBSModels.RemoveDesiredLRPRequest, remove_desired_lrp_request
      end
    end
  end
end
