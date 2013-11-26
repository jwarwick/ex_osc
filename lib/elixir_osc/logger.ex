defmodule ElixirOsc.Logger do
  use GenEvent.Behaviour

  def start_logger do
    pid = {ElixirOsc.Logger, make_ref}
    :ok = ElixirOsc.Events.subscribe(pid)
    {:ok, pid}
  end

  def stop_logger(pid) do
    ElixirOsc.Events.unsubscribe(pid) 
  end

  def handle_event(event, state) do
    IO.inspect event
    {:ok, state}
  end
end

