defmodule BBSEndpointMqConsummer do
  use GenServer
  use AMQP

  @exchange "bbs_exchange"
  @queue "bbs_endpoint"

  def start_link(rabbitmq_address, bbs_address) do
    GenServer.start_link(__MODULE__, rabbitmq_address: rabbitmq_address, bbs_address: bbs_address)
  end

  def init(rabbitmq_address: rabbitmq_address, bbs_address: bbs_address) do
    BBSHTTPClient.init
    {:ok, conn} = Connection.open(rabbitmq_address)
    {:ok, chan} = Channel.open(conn)

    Queue.declare(chan, @queue, durable: true)
    Exchange.topic(chan, @exchange, durable: true)
    Queue.bind(chan, @queue, @exchange, routing_key: "#")
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    state = [bbs_address: bbs_address, chan: chan]
    {:ok, state}
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

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered, routing_key: endpoint}}, [bbs_address: bbs_address, chan: chan]) do
    spawn fn -> consume(chan, bbs_address, tag, redelivered, endpoint, payload) end
    {:noreply, [bbs_address: bbs_address, chan: chan]}
  end

  defp consume(channel, bbs_address, tag, redelivered, endpoint, payload) do
    try do
      endpoint_consumer bbs_address, endpoint, payload
      Basic.ack channel, tag
    rescue
      exception ->
        IO.puts exception
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Basic.reject channel, tag, requeue: not redelivered
    end
  end

  defp endpoint_consumer(bbs_address, endpoint, payload) do
    IO.puts endpoint
    case endpoint do
      "Ping" ->
        {:ok, encoded_response} = BBSHTTPClient.ping bbs_address
        IO.puts BBSModels.PingResponse.decode(encoded_response).available
      _ -> IO.puts "DEFAULT"
    end
  end
end
