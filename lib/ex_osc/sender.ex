defmodule ExOsc.Sender do
  use GenServer

  def send_message(ip_tuple, port, {path, args}) do
    data = OSC.Message.construct(path, args)
    GenServer.cast(:osc_sender, {:osc_message, ip_tuple, port, data})
  end

  def start_link(_args) do
    GenServer.start_link __MODULE__, :ok, name: :osc_sender
  end

  def init(:ok) do
    :gen_udp.open(0, [:binary, {:active, true}])
  end

  def handle_cast({:osc_message, ip, port, data}, socket) do
    :ok = :gen_udp.send(socket, ip, port, data)
    {:noreply, socket}
  end
end
