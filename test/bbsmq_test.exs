defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "bbs_test_queue"

  defmodule MyEventHandler do
    use BBSMqClient.EventHandler, routing_key: "actual_lrp.*"

    def handle_event({event, %{channel: channel, payload: payload, meta_data: meta_data}}) do
      IO.puts event
      AMQP.Basic.ack channel, meta_data.delivery_tag
    end
  end

  setup do
    System.put_env("BBSMQ_RABBITMQ_ADDR", @rabbitmq_address)
    System.put_env("BBSMQ_CLIENT_RABBITMQ_ADDR", @rabbitmq_address)
    System.put_env("BBSMQ_BBS_ADDR", @bbs_address)

    {:ok, pid} = BBSMqClient.start_link("bbsmq_test_queue")
    {:ok, conn} = Connection.open(rabbitmq_address)
    {:ok, chan} = Channel.open(conn)

    {:ok, %{pid: pid, chan: chan}}
  end

  test "BBSMq send Ping", %{pid: pid, chan: chan} do
    BBSMqClient.ping(pid, fn(payload, meta_data) ->
      assert payload.available == true
    end)
  end

end
