defmodule ExOsc.Parser do
  use GenServer.Behaviour

  def start_link, do: start_link([])
  def start_link(_options) do
    :gen_server.start_link({:local, :osc_parser}, __MODULE__, [], [])
  end

  def handle_info({:osc_msg, data}, state) do
    result = OSC.Message.parse data
    ExOsc.Events.send_event(result)
    {:noreply, state}
  end

end

