defmodule BBSMqTest do
  use ExUnit.Case
  doctest BBSMq

  @rabbitmq_address "amqp://guest:guest@localhost"
  @bbs_address "http://127.0.0.1:8889"
  @reply_to "test_queue"

  test "BBSMq.Consumer routing_key_to_endpoint" do
    endpoint = BBSMq.Consumer.routing_key_to_endpoint("ActualLRPGroups")
    assert endpoint == :actual_lrp_groups
  end
end
