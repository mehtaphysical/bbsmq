defmodule BBSMq.Consumer do
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

  def handle_info({:basic_deliver, payload, meta_data}, [bbs_address: bbs_address, chan: chan]) do
    spawn fn -> consume(chan, bbs_address, payload, meta_data) end
    {:noreply, [bbs_address: bbs_address, chan: chan]}
  end


  defp consume(channel, bbs_address, payload, meta_data) do
    try do
      endpoint_consumer channel, bbs_address, meta_data.routing_key, meta_data.reply_to, payload
      Basic.ack channel, meta_data.delivery_tag
    rescue
      exception ->
        IO.puts exception
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Basic.reject channel, meta_data.delivery_tag, requeue: not meta_data.redelivered
    end
  end

  defp endpoint_consumer(channel, bbs_address, routing_key, reply_to, payload) do
    {:ok, encoded_response} = apply(BBSHTTPClient, routing_key_to_endpoint(routing_key), [bbs_address, payload])
    Basic.publish channel, "", reply_to, encoded_response
  end

  def routing_key_to_endpoint(routing_key) do
    String.split(routing_key, "") |> Enum.map(fn(letter) ->
      downcased_letter = String.downcase(letter)
      if String.equivalent?(letter, downcased_letter) do
        letter
      else
        "_" <> downcased_letter
      end
    end) |> Enum.join("") |> String.lstrip(?_)
    |> String.replace("l_r_p", "lrp") |> String.to_atom
  end
end
