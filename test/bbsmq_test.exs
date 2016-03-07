defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"

  test "BBSMq send Ping" do
    {:ok, pid} = BBSMq.start @rabbitmq_address, @bbs_address

    {:ok, conn} = AMQP.Connection.open(@rabbitmq_address)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish chan, "bbs_exchange", "Ping", "ok"

    receive do
      {:msg,} -> exit(1)
    end
  end
end
