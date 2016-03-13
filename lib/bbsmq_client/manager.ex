defmodule BBSMqClient.Manager do
  use GenServer
  use AMQP

  require BBSModels

  def start_link(queue_name \\ "default_bbs_client") do
    GenServer.start_link(__MODULE__, queue_name)
  end

  def init(queue_name) do
    {:ok, conn} = AMQP.Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = AMQP.Channel.open(conn)

    Queue.declare(chan, queue_name, durable: true)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, queue_name)
    {:ok, %{chan: chan, queue_name: queue_name, callbacks: %{}}}
  end

  # Publisher
  def handle_cast({:send_message, %{endpoint: endpoint, payload: payload}, callback},
                  %{chan: chan, queue_name: queue_name, callbacks: callbacks}) do
    message_id = create_message_id
    AMQP.Basic.publish(chan, "bbs_exchange", endpoint, payload, reply_to: queue_name, correlation_id: message_id)
    {:noreply, %{chan: chan, queue_name: queue_name, callbacks: Map.put(callbacks, message_id, callback)}}
  end

  # Consumer

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
    handler_id = meta_data.correlation_id
    {handler, updated_callbacks} = Map.pop(state.callbacks, handler_id)
    spawn fn -> consume(state.chan, handler, payload, meta_data) end
    new_state = %{chan: state.chan, queue_name: state.queue_name, callbacks: updated_callbacks}
    {:noreply, new_state}
  end

  defp consume(channel, handler, payload, meta_data) do
    try do
      {_, _, processor} = header_by_name(meta_data.headers, "processor")
      decoded_payload = decode_payload(processor, payload)
      apply(handler,[decoded_payload, meta_data])
      Basic.ack channel, meta_data.delivery_tag
    rescue
      exception ->
        IO.puts exception.message
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Basic.reject channel, meta_data.delivery_tag, requeue: not meta_data.redelivered
    end
  end

  defp create_message_id do
    UUID.uuid4()
  end

  defp decode_payload(processor, payload) do
    apply(Module.concat(BBSModels, processor), :decode, [payload])
  end

  defp header_by_name(headers, name) do
    headers |>
    Enum.find(fn(header) ->
      {x, _, _} = header
      x == name
    end)
  end
end
