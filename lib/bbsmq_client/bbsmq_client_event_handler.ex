defmodule BBSMqClient.EventHandler do

  defmacro __using__(routing_keys: routing_keys) do
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
                      %{pid: self, routing_keys: unquote(routing_keys), queue_name: queue_name}})

        setup()
        {:ok, chan}
      end

      def setup do
        # Override
      end

      def handle_call({:bbs_event, payload, meta_data}, _from, chan) do
        handle_event({meta_data.routing_key, %{channel: chan, payload: payload, meta_data: meta_data}})
        {:reply, "", chan}
      end

      defoverridable [setup: 0]
    end
  end
end
