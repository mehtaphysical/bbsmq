defmodule BBSMqClient do
  def start_link(queue_name) do
    rabbitmq_address = System.get_env("BBSMQ_CLIENT_RABBITMQ_ADDR")
    BBSMqClient.Manager.start_link rabbitmq_address, queue_name
  end

  for endpoint <- BBSHTTPClient.__info__(:functions)
                  |> Enum.reject(fn(ele) -> ele == {:init, 0} end) do
    case endpoint  do
      {function_name, 1} ->
        def unquote(function_name)(pid, callback) do
          send_message pid, %{endpoint: atom_to_endpoint_name(unquote(function_name)), payload: ""}, callback
        end
      {function_name, 2} ->
        def unquote(function_name)(pid, payload, callback) do
          send_message pid, %{endpoint: atom_to_endpoint_name(unquote(function_name)), payload: payload}, callback
        end
    end
  end

  defp send_message(pid, message, callback) do
    GenServer.cast(pid, {:send_message, message, callback})
  end

  defp atom_to_endpoint_name(endpoint_atom) do
    endpoint_atom
    |> Atom.to_string
    |> String.split("_")
    |> Enum.map(fn(word) ->
      cond do
        String.starts_with?(word, "lrp") ->
          String.upcase(word) |> String.replace("S", "s")
        true ->
          String.capitalize(word)
      end
    end)
    |> Enum.join("")
  end
end
