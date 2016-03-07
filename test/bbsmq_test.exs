defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "test_queue"

  test "BBSMq send Ping" do
    test_pid = self()
    {:ok, pid} = BBSMq.start @rabbitmq_address, @bbs_address

    {:ok, conn} = AMQP.Connection.open(@rabbitmq_address)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Queue.declare chan, @reply_to

    AMQP.Basic.publish chan, "bbs_exchange", "Ping", "ok", reply_to: @reply_to

    AMQP.Queue.subscribe chan, @reply_to, fn(payload, _meta) ->
      assert BBSModels.PingResponse.decode(payload).available
      send test_pid, {:done}
    end

    receive do
      {:done} ->
        AMQP.Channel.close(chan)
        AMQP.Connection.close(conn)
    end
  end
end
