defmodule ExOsc.Listener do
  @moduledoc """
  GenServer process to listen for OSC messages
  """
  use GenServer

  @default_udp_port 8000

  def start_link(options \\ []) do
    port = Keyword.get(options, :port, @default_udp_port)
    GenServer.start_link(__MODULE__, port: port)
  end

  def init(port: port) do
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])
    {:ok, socket}
  end

  def handle_info(_msg = {:udp, _socket, _send_ip, _send_port, data}, socket) do
    data
    |> OSC.Message.parse
    |> ExOsc.Events.send_event
    {:noreply, socket}
  end
end
