defmodule BBSClient do

  @ping_path "/v1/ping"

  @domain_list_path "/v1/domains/list"
  @domain_upsert_path "/v1/domains/upsert"

  @cell_list_path "/v1/cells/list.r1"

  def ping(bbs_address) do
    BBSHTTPClient.request(bbs_address <> @ping_path)
  end

  def domain_list(bbs_address) do
    BBSHTTPClient.request(bbs_address <> @domain_list_path)
  end

  def domain_upsert(bbs_address, upsert_domain_request) do
    url = bbs_address <> @domain_upsert_path
    BBSHTTPClient.protobuf_request url, BBSModels.UpsertDomainRequest, upsert_domain_request
  end

  def cell_list(bbs_address) do
    BBSHTTPClient.get_request bbs_address
  end

  defmodule DesiredLRP do
    use DesiredLRPClient
  end

  defmodule ActualLRP do
    use ActualLRPClient
  end
end
