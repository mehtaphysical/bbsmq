defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "test_queue"

  setup do
    {:ok, conn} = AMQP.Connection.open(@rabbitmq_address)
    {:ok, chan} = AMQP.Channel.open(conn)
    {:ok, %{chan: chan}}
  end

  test "BBSMq send Ping", %{chan: chan} do
    AMQP.Queue.declare chan, @reply_to

    AMQP.Queue.bind(chan, @reply_to, "bbs_events", routing_key: "#")

    receive do
      {:done} ->

    end
  end

end
