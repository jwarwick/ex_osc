defmodule ExOsc.Listener do
  use GenServer.Behaviour

  @default_udp_port 8000

  def start_link, do: start_link([])
  def start_link(options) do
    port = Keyword.get(options, :port, @default_udp_port)
    :gen_server.start_link(__MODULE__, [port: port], [])
  end

  def init([port: port]) do
    :gen_udp.open(port, [:binary, {:active, true}])
  end
  
  def handle_info(_msg = {:udp, _socket, _send_ip, _send_port, data}, socket) do
    send(:osc_parser, {:osc_msg, data})
    {:noreply, socket}
  end
end

