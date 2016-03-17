defmodule ExOsc.Supervisor do
  use Supervisor

  def start_link, do: start_link([])
  def start_link(args) do
    Supervisor.start_link __MODULE__, args
  end

  def init(args) do
    children = [
      # Define workers and child supervisors to be supervised
      # worker(ExOsc.Worker, [])
      worker(ExOsc.Listener, args),
      worker(ExOsc.Parser, args),
      worker(ExOsc.Sender, args),
    ]

    {:ok, _pid} = ExOsc.Events.start_link

    supervise(children, strategy: :one_for_one)
  end
end
