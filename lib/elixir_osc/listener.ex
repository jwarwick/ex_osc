defmodule ElixirOsc.Listener do
  use GenServer.Behaviour

  @default_udp_port 8000

  def start_link, do: start_link([])
  def start_link(options) do
    port = Keyword.get(options, :port, @default_udp_port)
    :gen_server.start_link({:local, :osc_listener}, __MODULE__, [port: port], [])
  end

  def init([port: port]) do
    :gen_udp.open(port, [:binary, {:active, true}])
  end
  
  def handle_info(msg, port) do
    IO.inspect msg
    {:noreply, port}
  end
end

