defmodule BBSMq.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    rabbitmq_address = System.get_env("BBSMQ_RABBITMQ_ADDR")
    bbs_address = System.get_env("BBSMQ_BBS_ADDR")
    children = [
      worker(BBSMq.Consumer, [rabbitmq_address, bbs_address])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
