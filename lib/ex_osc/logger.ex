defmodule ExOsc.Logger do
  use GenEvent

  def start_logger do
    pid = {ExOsc.Logger, make_ref}
    :ok = ExOsc.Events.subscribe(pid)
    {:ok, pid}
  end

  def stop_logger(pid) do
    ExOsc.Events.unsubscribe(pid) 
  end

  def handle_event(event, state) do
    IO.inspect event
    {:ok, state}
  end
end

