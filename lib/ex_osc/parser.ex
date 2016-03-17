defmodule ExOsc.Parser do
  use GenServer

  def start_link, do: start_link([])
  def start_link(_options) do
    GenServer.start_link __MODULE__, :ok, name: :osc_parser
  end

  def handle_info({:osc_msg, data}, state) do
    result = OSC.Message.parse data
    ExOsc.Events.send_event(result)
    {:noreply, state}
  end

end
