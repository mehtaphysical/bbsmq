defmodule BBSHTTPClient do

  @ping_path "/v1/ping"

  @cell_list_path "/v1/cells/list.r1"

  def init do
    HTTPoison.start
  end

  def ping(bbs_address) do
    request(bbs_address <> @ping_path)
  end

  def cell_list(bbs_address) do
    get_request bbs_address
  end

  defmodule DomainClient do
    @domain_list_path "/v1/domains/list"
    @domain_upsert_path "/v1/domains/upsert"

    def domain_list(bbs_address) do
      BBSHTTPClient.request(bbs_address <> @domain_list_path)
    end

    def domain_upsert(bbs_address, upsert_domain_request) do
      url = bbs_address <> @domain_upsert_path
      BBSHTTPClient.request url, upsert_domain_request
    end
  end

  defmodule ActualLRPClient do
    @list_path "/v1/actual_lrp_groups/list"
    @list_by_process_guid_path "/v1/actual_lrp_groups/list_by_process_guid"
    @get_by_process_guid_and_index_path "/v1/actual_lrp_groups/get_by_process_guid_and_index"

    def list(bbs_address, actual_lrp_groups_request \\ []) do
      url = bbs_address <> @list_path
      BBSHTTPClient.request url, actual_lrp_groups_request
    end

    def list_by_process_guid(bbs_address, actual_lrp_groups_by_process_guid_request) do
      url = bbs_address <> @list_by_process_guid_path
      BBSHTTPClient.request url, actual_lrp_groups_by_process_guid_request
    end

    def get_by_process_guid_and_index(bbs_address, actual_lrp_groups_by_process_guid_and_index_request) do
      url = bbs_address <> @get_by_process_guid_and_index_path
      BBSHTTPClient.request url, actual_lrp_groups_by_process_guid_and_index_request
    end
  end

  defmodule DesiredLRPClient do
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
      BBSHTTPClient.request url, desired_lrp_by_process_guid_request
    end

    def scheduling_infos_list(bbs_address, desired_lrps_request) do
      url = bbs_address <> @scheduling_infos_list_path
      BBSHTTPClient.request url, desired_lrps_request
    end

    def create(bbs_address, desired_lrp_request) do
      url = bbs_address <> @create_desired_lrp_path
      BBSHTTPClient.request url, desired_lrp_request
    end

    def update(bbs_address, update_desired_lrp_request) do
      url = bbs_address <> @update_desired_lrp_path
      BBSHTTPClient.request url, update_desired_lrp_request
    end

    def remove(bbs_address, remove_desired_lrp_request) do
      url = bbs_address <> @remove_desired_lrp_path
      BBSHTTPClient.request url, remove_desired_lrp_request
    end
  end

  defp request(url, body \\ "") do
    case HTTPoison.post url, body do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found :("}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      end
  end

  defp protobuf_request(url, processor, body) do
    unencoded_request_body = processor.new(body)
    encoded_request_body = processor.encode(unencoded_request_body)
    request url, encoded_request_body
  end

  defp get_request(url) do
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found :("}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      end
  end

end
