defmodule ElixirOsc.Events do

  def start_link(), do: start_link([])
  def start_link(_args) do
    :gen_event.start_link({:local, :osc_events})
    {:ok, []}
  end

  def subscribe(handler), do: subscribe(handler, [])
  def subscribe(handler, args) do
    :gen_event.add_handler(:osc_events, handler, args)
  end

  def unsubscribe(handler), do: unsubscribe(handler, [])
  def unsubscribe(handler, args) do
    :gen_event.delete_handler(:osc_events, handler, args)
  end

  def send_event(msg) do
    :gen_event.notify(:osc_events, {:osc_event, msg})
  end

end

