defmodule BBSMq.Event.Publisher do
  use GenServer
  use AMQP

  @exchange "bbs_events"

  def start_link(rabbitmq_address, name) do
    GenServer.start_link(__MODULE__,
                        [rabbitmq_address: rabbitmq_address],
                        name: name)
  end

  def init(rabbitmq_address: rabbitmq_address) do
    {:ok, conn} = Connection.open(rabbitmq_address)
    {:ok, chan} = Channel.open(conn)

    Exchange.topic(chan, @exchange, durable: true)
    {:ok, chan}
  end

  def handle_cast({:publish, %{event: event, data: data}}, chan) do
    processor = event_to_processor event
    AMQP.Basic.publish chan, @exchange, event_to_routing_key(event), data,
                      headers: [processor: processor]
    {:noreply, chan}
  end

  defp event_to_processor(event) do
    event <> "_event"
    |> String.split("_")
    |> Enum.map(fn(word) ->
      if String.starts_with?(word, "lrp")  do
        String.upcase(word)
      else
        String.capitalize(word)
      end
    end)
    |> Enum.join
  end

  defp event_to_routing_key(event) do
    String.replace(event, ~r/\_(.*)\_(.*)$/, "_\\1.\\2")
  end

end
