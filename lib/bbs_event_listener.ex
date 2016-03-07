defmodule BbsEventListener do
  
  def init do
    HTTPoison.start
  end

  def listen(queue_stream, url) do
    HTTPoison.get! url, [], [stream_to: spawn(fn -> handle_chunk queue_stream end), recv_timeout: :infinity, connect_timeout: 5000]
  end

  defp handle_chunk(queue_stream, existing_payload \\ "") do
    receive do
      %HTTPoison.AsyncChunk{chunk: payload} ->
        full_payload = existing_payload <> payload
        cond do
          String.ends_with?(full_payload, "\n\n") ->
            spawn fn -> handle_event queue_stream, parse_data(full_payload) end
            handle_chunk queue_stream
          true ->
            handle_chunk queue_stream, full_payload
        end
    end
  end

  defp handle_event(queue_stream, event_info) do
    encoded_message = event_info.data
    send queue_stream, {:publish_event, %{event: event_info.event, data: encoded_message}}
  end

  defp parse_data(data) do
    String.replace_trailing(data, "\n", "") |>  String.split("\n") |> Enum.map(&(String.split(&1, ": "))) |> Enum.map(&({String.to_atom(hd &1), hd (tl &1)})) |> Enum.into(%{})
  end

end
