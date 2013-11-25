defmodule ElixirOsc.Logger do
  use GenEvent.Behaviour

  def handle_event(event, state) do
    IO.inspect event
    {:ok, state}
  end
end

