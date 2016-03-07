defmodule BBSHTTPClient do

  def request(url, body \\ "") do
    case HTTPoison.post url, body do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found :("}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      end
  end

  def protobuf_request(url, processor, body) do
    unencoded_request_body = processor.new(body)
    encoded_request_body = processor.encode(unencoded_request_body)
    request url, encoded_request_body
  end

  def get_request(url) do
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
