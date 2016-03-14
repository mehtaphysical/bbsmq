defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "test_queue"

  test "event_to_routing_key" do
    routing_key = BBSMq.Event.Publisher.event_to_routing_key("desired_lrp_created")
    assert routing_key == "desired_lrp.created"
  end
end
