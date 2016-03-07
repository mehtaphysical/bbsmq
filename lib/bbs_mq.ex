defmodule BbsMq do
  use GenServer
  use AMQP

  @exchange "bbs_exchange"

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_opts) do
    {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = Channel.open(conn)

    Exchange.direct(chan, @exchange, durable: true)
    {:ok, chan}
  end

  def handle_info({:publish_event, %{event: event, data: payload}}, chan) do
    spawn fn -> event_publisher(chan, event, payload) end
    {:noreply, chan}
  end

  defp event_publisher(chan, event, payload) do
    IO.puts event
    Basic.publish chan, @exchange, event, payload
  end
end
