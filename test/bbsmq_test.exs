defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "bbs_test_queue"

  defmodule MyEventHandler do
    require BBSMQClient.EventHandler
    use BBSMQClient.EventHandler, routing_key: "actual_lrp_created"

    def handle_event(%{channel: chan, payload: payload, meta_data: meta_data}) do
      IO.puts meta_data.routing_key
    end
  end

  setup do
    {:ok, conn} = AMQP.Connection.open(@rabbitmq_address)
    {:ok, chan} = AMQP.Channel.open(conn)
    {:ok, %{chan: chan}}
  end

  test "BBSMq send Ping", %{chan: chan} do
    {:ok, pid} = BBSMqClient.start_link(@reply_to)
    BBSMqClient.ping(pid, fn(ping_response, _) ->
      IO.puts ping_response.available
    end)

    receive do
      {:done} ->

    end
  end

end
