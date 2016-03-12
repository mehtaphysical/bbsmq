defmodule BBSMq.Event.Listener do
  use GenServer

  @actual_lrp_events_path "/v1/actual_lrp_events"
  @desired_lrp_events_path "/v1/desired_lrp_events"
  @task_events_path "/v1/task_events"

  def start_actual_lrp_link(consumer_pid, bbs_address, name \\ :bbsmq_actual_lrp_events_listener) do
    url = bbs_address <> @actual_lrp_events_path
    start_link(consumer_pid, url, name)
  end

  def start_desired_lrp_link(consumer_pid, bbs_address, name \\ :bbsmq_desired_lrp_events_listener) do
    url = bbs_address <> @desired_lrp_events_path
    start_link(consumer_pid, url, name)
  end

  def start_task_link(consumer_pid, bbs_address, name \\ :bbsmq_task_events_listener) do
    url = bbs_address <> @task_events_path
    start_link(consumer_pid, url, name)
  end

  def start_link(consumer_pid, url, name) do
    GenServer.start_link(__MODULE__, [event_url: url, consumer_pid: consumer_pid], name: name )
  end

  def init(event_url: url, consumer_pid: consumer_pid) do
    HTTPoison.start
    HTTPoison.get! url, [], [stream_to: self, recv_timeout: :infinity, connect_timeout: 5000]
    {:ok, %{existing_payload: "", consumer_pid: consumer_pid}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200, id: _}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{headers: _}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: payload},
                  %{existing_payload: existing_payload, consumer_pid: consumer_pid}) do
    full_payload = existing_payload <> payload
    cond do
      String.ends_with?(full_payload, "\n\n") ->
        handle_event consumer_pid, parse_data(full_payload)
        {:noreply, %{existing_payload: "", consumer_pid: consumer_pid}}
      true ->
        {:noreply, %{existing_payload: full_payload, consumer_pid: consumer_pid}}
    end
  end

  defp handle_event(pid, event_info) do
    GenServer.cast(pid, {:publish, %{event: event_info.event, data: event_info.data}})
  end

  defp parse_data(data) do
    String.replace_trailing(data, "\n", "") |>  String.split("\n") |> Enum.map(&(String.split(&1, ": "))) |> Enum.map(&({String.to_atom(hd &1), hd (tl &1)})) |> Enum.into(%{})
  end

end
