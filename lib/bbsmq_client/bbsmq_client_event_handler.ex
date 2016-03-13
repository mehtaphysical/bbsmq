defmodule BBSMQClient.EventHandler do

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
        {:ok, conn} = AMQP.Connection.open("amqp://guest:guest@localhost")
        {:ok, chan} = AMQP.Channel.open(conn)

        AMQP.Queue.declare(chan, queue_name, durable: true)
        AMQP.Queue.bind(chan, queue_name, "bbs_events", routing_key: unquote(routing_key))
        # Register the GenServer process as a consumer
        {:ok, _consumer_tag} = AMQP.Basic.consume(chan, queue_name)
        {:ok, %{chan: chan, queue_name: queue_name, callbacks: %{}}}
      end

      # Confirmation sent by the broker after registering this process as a consumer
      def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
        {:noreply, state}
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
        {:stop, :normal, state}
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
        {:noreply, state}
      end

      def handle_info({:basic_deliver, payload, meta_data}, state) do
        spawn fn -> handle_event({meta_data.routing_key, %{channel: state.chan, payload: payload, meta_data: meta_data}}) end
        AMQP.Basic.ack state.chan, meta_data.delivery_tag
        {:noreply, state}
      end
    end
  end
end
