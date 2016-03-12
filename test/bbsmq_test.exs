defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "test_queue"

  def loop(times, f) do
    cond do
      times > 0 ->
        f.()
        loop(times - 1, f)
      true ->
          IO.puts "loop complete"
    end
  end

  test "BBSMq send Ping" do
    test_pid = self()
    {:ok, _} = BBSMq.start @rabbitmq_address, @bbs_address

    {:ok, conn} = AMQP.Connection.open(@rabbitmq_address)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Queue.declare chan, @reply_to

    AMQP.Queue.subscribe chan, @reply_to, fn(payload, _meta) ->
      #Enum.each(BBSModels.DomainsResponse.decode(payload).domains, &(IO.puts &1))
      #assert length(BBSModels.DomainsResponse.decode(payload).domains) > 0
      send test_pid, {:done}
    end

    loop(100, fn ->
      AMQP.Basic.publish(chan, "bbs_exchange", "Ping", "ok", reply_to: @reply_to, correlation_id: "1234")
    end)

    receive do
      {:done} ->
        AMQP.Channel.close(chan)
        AMQP.Connection.close(conn)
    end
  end

end
