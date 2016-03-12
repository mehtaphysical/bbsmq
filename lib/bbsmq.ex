defmodule BBSMq do
  use Application

  def start(_type, _args) do
    BBSMq.Endpoint.Supervisor.start_link
    BBSMq.Event.Supervisor.start_link
  end
end
