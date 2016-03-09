defmodule BBSMq do
  use Application

  def start(_type, _args) do
    BBSMq.Supervisor.start_link
  end
end
