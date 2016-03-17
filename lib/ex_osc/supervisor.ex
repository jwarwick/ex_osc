defmodule ExOsc.Supervisor do
  use Supervisor

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      # Define workers and child supervisors to be supervised
      worker(GenEvent, [[name: :osc_events]]),
      worker(ExOsc.Listener, args),
      worker(ExOsc.Sender, args)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
