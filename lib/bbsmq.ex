defmodule BBSMq do
  def start(rabbitmq_address, bbs_address) do
    BBSEndpointMqConsummer.start_link rabbitmq_address, bbs_address
  end
end
