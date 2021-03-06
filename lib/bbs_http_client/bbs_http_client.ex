defmodule BBSHTTPClient do

  @ping_path "/v1/ping"

  @cell_list_path "/v1/cells/list.r1"

  @domain_list_path "/v1/domains/list"
  @domain_upsert_path "/v1/domains/upsert"

  @actual_lrp_groups_path "/v1/actual_lrp_groups/list"
  @actual_lrp_groups_by_process_guid_path "/v1/actual_lrp_groups/list_by_process_guid"
  @actual_lrp_groups_by_process_guid_and_index_path "/v1/actual_lrp_groups/get_by_process_guid_and_index"

  @desired_lrps_path "/v1/desired_lrps/list.r1"
  @desired_lrps_by_process_guid_path "/v1/desired_lrps/get_by_process_guid.r1"
  @desired_lrp_scheduling_infos_path "/v1/desired_lrp_scheduling_infos/list"
  @desire_lrp_path "/v1/desired_lrp/desire"
  @update_desired_lrp_path "/v1/desired_lrp/update"
  @remove_desired_lrp_path "/v1/desired_lrp/remove"

  def init do
    HTTPoison.start
  end

  def ping(bbs_address, _ \\ "") do
    request(bbs_address <> @ping_path, BBSModels.PingResponse)
  end

  def cells(bbs_address, _ \\ "") do
    get_request(bbs_address <> @cell_list_path, BBSModels.CellsResponse)
  end

  # DomainClient

  def domains(bbs_address, _ \\ "") do
    request(bbs_address <> @domain_list_path, BBSModels.DomainsResponse)
  end

  def upsert_domain(bbs_address, upsert_domain_request) do
    url = bbs_address <> @domain_upsert_path
    request(url, BBSModels.UpsertDomainResponse, upsert_domain_request)
  end

  # ActualLRPClient

  def actual_lrp_groups(bbs_address, actual_lrp_groups_request \\ []) do
    url = bbs_address <> @actual_lrp_groups_path
    request(url, BBSModels.ActualLRPGroupsResponse, actual_lrp_groups_request)
  end

  def actual_lrp_groups_by_process_guid(bbs_address, actual_lrp_groups_by_process_guid_request) do
    url = bbs_address <> @actual_lrp_groups_by_process_guid_path
    request(url, BBSModels.ActualLRPGroupsResponse, actual_lrp_groups_by_process_guid_request)
  end

  def actual_lrp_groups_by_process_guid_and_index(bbs_address, actual_lrp_groups_by_process_guid_and_index_request) do
    url = bbs_address <> @actual_lrp_groups_by_process_guid_and_index_path
    request(url, BBSModels.ActualLRPGroupResponse, actual_lrp_groups_by_process_guid_and_index_request)
  end

  # DesiredLRPClient

  def desired_lrps(bbs_address, desired_lrps_request \\ "") do
    request(bbs_address <> @desired_lrps_path, BBSModels.DesiredLRPsResponse, desired_lrps_request)
  end

  def desired_lrp_by_process_guid(bbs_address, desired_lrp_by_process_guid_request) do
    url = bbs_address <> @desired_lrps_by_process_guid_path
    request(url, BBSModels.DesiredLRPResponse, desired_lrp_by_process_guid_request)
  end

  def desired_lrp_scheduling_infos(bbs_address, desired_lrps_request) do
    url = bbs_address <> @desired_lrp_scheduling_infos_path
    request(url, BBSModels.DesiredLRPSchedulingInfosResponse, desired_lrps_request)
  end

  def desire_lrp(bbs_address, desired_lrp_request) do
    url = bbs_address <> @desire_lrp_path
    request(url, BBSModels.DesiredLRPLifecycleResponse, desired_lrp_request)
  end

  def update_desired_lrp(bbs_address, update_desired_lrp_request) do
    url = bbs_address <> @update_desired_lrp_path
    request(url, BBSModels.DesiredLRPLifecycleResponse, update_desired_lrp_request)
  end

  def remove_desired_lrp(bbs_address, remove_desired_lrp_request) do
    url = bbs_address <> @remove_desired_lrp_path
    request(url, BBSModels.DesiredLRPLifecycleResponse, remove_desired_lrp_request)
  end

  defp request(url, processor, body \\ "") do
    case HTTPoison.post url, body do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body, processor}
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

  defp get_request(url, processor) do
    case HTTPoison.get url do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body, processor}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found :("}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      end
  end

end
