defmodule ExOsc.Sender do
  @moduledoc """
  GenServer process to handle sending OSC messages
  """
  use GenServer

  def send_message(ip_tuple, port, {path, args}) do
    data = OSC.Message.construct(path, args)
    GenServer.cast(__MODULE__, {:osc_message, ip_tuple, port, data})
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, true}])
    {:ok, socket}
  end

  def handle_cast({:osc_message, ip, port, data}, socket) do
    :ok = :gen_udp.send(socket, ip, port, data)
    {:noreply, socket}
  end
end
