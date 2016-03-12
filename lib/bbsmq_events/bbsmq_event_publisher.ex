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
    AMQP.Basic.publish chan, @exchange, event, data
    {:noreply, chan}
  end

end