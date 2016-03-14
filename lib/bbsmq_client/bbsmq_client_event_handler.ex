defmodule BBSMqClient.EventHandler do

  defmacro __using__(routing_key: routing_key) do
    if is_nil(routing_key) do
      raise "EventHandlers must declare a routing_key`)"
    end

    quote do
      use GenServer

      def start_link(queue_name) do
        GenServer.start_link(__MODULE__, queue_name)
      end

      def init(queue_name) do
        {:ok, chan} = GenServer.call(:bbsmq_manager,
                      {:register_event_handler,
                      %{pid: self, routing_key: unquote(routing_key), queue_name: queue_name}})
        {:ok, chan}
      end

      def handle_call({:bbs_event, payload, meta_data}, _from, chan) do
        handle_event({meta_data.routing_key, %{channel: chan, payload: payload, meta_data: meta_data}})
        {:reply, "", chan}
      end
    end
  end
end
