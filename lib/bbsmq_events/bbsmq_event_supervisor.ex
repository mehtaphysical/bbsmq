defmodule BBSMq.Event.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    rabbitmq_address = System.get_env("BBSMQ_RABBITMQ_ADDR")
    bbs_address = System.get_env("BBSMQ_BBS_ADDR")
    children = [
      worker(BBSMq.Event.Publisher, [rabbitmq_address, :bbsmq_event_publisher]),
      worker(BBSMq.Event.Listener, [:bbsmq_event_publisher, bbs_address], [id: :start_actual_lrp_link, function: :start_actual_lrp_link]),
      worker(BBSMq.Event.Listener, [:bbsmq_event_publisher, bbs_address], [id: :start_desired_lrp_link, function: :start_desired_lrp_link]),
      worker(BBSMq.Event.Listener, [:bbsmq_event_publisher, bbs_address], [id: :start_task_link, function: :start_task_link])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
