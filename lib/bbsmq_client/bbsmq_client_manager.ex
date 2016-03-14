defmodule BBSMqClient.Manager do
  use GenServer
  use AMQP

  require BBSModels

  def start_link(rabbitmq_address, queue_name \\ "default_bbs_client") do
    GenServer.start_link(__MODULE__,
                        [rabbitmq_address: rabbitmq_address, queue_name: queue_name],
                        name: :bbsmq_manager)
  end

  def init(rabbitmq_address: rabbitmq_address, queue_name: queue_name) do
    {:ok, conn} = AMQP.Connection.open(rabbitmq_address)
    {:ok, chan} = AMQP.Channel.open(conn)

    Queue.declare(chan, queue_name, durable: true)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, queue_name)
    {:ok, %{chan: chan, queue_name: queue_name, endpoint_callbacks: %{}, event_handlers: %{}}}
  end

  # EventHandler registration
  def handle_cast({:register_event_handler, %{pid: pid, routing_key: routing_key, queue_name: queue_name}}, state) do
    AMQP.Queue.declare(state.chan, queue_name, durable: true)
    AMQP.Queue.bind(state.chan, queue_name, "bbs_events", routing_key: routing_key)

    {_, new_event_handlers} = Map.get_and_update(state.event_handlers, routing_key, fn(current_handlers) ->
      if is_nil(current_handlers) do
        {current_handlers, [pid]}
      else
        {current_handlers, current_handlers ++ pid}
      end
    end)

    new_state = %{ state | :event_handlers => new_event_handlers}
    {:noreply, new_state}
  end

  # Publisher
  def handle_cast({:send_message, %{endpoint: endpoint, payload: payload}, callback},
                  %{chan: chan, queue_name: queue_name, endpoint_callbacks: callbacks, event_handlers: event_handlers}) do
    message_id = create_message_id
    AMQP.Basic.publish(chan, "bbs_exchange", endpoint, payload, reply_to: queue_name, correlation_id: message_id)
    {:noreply, %{
      chan: chan,
      queue_name: queue_name,
      endpoint_callbacks: Map.put(callbacks, message_id, callback),
      event_handlers: event_handlers
    }}
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
    if is_bitstring(meta_data.correlation_id) do
      handle_endpoint(payload, meta_data, state)
    else
      handle_event(payload, meta_data, state)
    end
  end

  defp handle_event(payload, meta_data, state) do
    meta_data.routing_key
    |> patterns_for_routing_key
    |> Enum.reduce([], fn(pattern, handler_pids) ->
      handler_pids ++ Map.get(state.event_handlers, pattern, [])
    end)
    |> Enum.each(&(spawn fn -> consume_event(state.chan, &1, payload, meta_data) end))
    {:noreply, state}
  end

  defp consume_event(channel, handler_pid, payload, meta_data) do
    try do
      GenServer.cast(handler_pid, {:bbs_event, payload, meta_data})
      AMQP.Basic.ack channel, meta_data.delivery_tag
    rescue
      exception ->
        # Todo remove pid from list
        GenServer.stop(handler_pid, :unreachable)
    end

  end

  defp handle_endpoint(payload, meta_data, state) do
    callback_id = meta_data.correlation_id
    {callback, updated_callbacks} = Map.pop(state.endpoint_callbacks, callback_id)
    spawn fn -> consume_endpoint(state.chan, callback, payload, meta_data) end
    new_state = %{
      chan: state.chan,
      queue_name: state.queue_name,
      endpoint_callbacks: updated_callbacks,
      event_handlers: state.event_handlers
    }

    {:noreply, new_state}
  end

  defp consume_endpoint(channel, callback, payload, meta_data) do
    try do
      {_, _, processor} = header_by_name(meta_data.headers, "processor")
      decoded_payload = decode_payload(processor, payload)
      apply(callback,[decoded_payload, meta_data])
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

  defp patterns_for_routing_key(routing_key) do
    routing_key_parts = String.split(routing_key, ".")
    routing_key_first_part = List.first(routing_key_parts)
    routing_key_last_part = List.last(routing_key_parts)
    patterns = [
      "#", "#.#", "#.*", "*.#", "*.*",
      (routing_key_first_part <> ".#"), (routing_key_first_part <> ".*"),
      ("#." <> routing_key_last_part), ("*." <> routing_key_last_part),
      routing_key
    ]
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
