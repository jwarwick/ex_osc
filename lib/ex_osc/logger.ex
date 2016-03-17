defmodule ExOsc.Logger do
  @moduledoc """
  Simple Logger process that listens for incoming events and inspects them.
  """

  use GenEvent
  require Logger

  def start_logger do
    pid = {__MODULE__, make_ref}
    :ok = GenEvent.add_handler(:osc_events, pid, [])
    {:ok, pid}
  end

  def stop_logger(pid) do
    :ok = GenEvent.remove_handler(:osc_events, pid, [])
  end

  def handle_event(event, state) do
    Logger.info "OSC: #{inspect event}"
    {:ok, state}
  end
end

