defmodule ExOsc do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, args) do
    ExOsc.Supervisor.start_link args
  end
end
