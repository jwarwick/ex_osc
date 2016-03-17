defmodule ExOsc.Mixfile do
  use Mix.Project

  def project do
    [ app: :ex_osc,
      version: "0.0.1",
      elixir: ">= 1.2.3",
      deps: deps ]
  end

  def application do
    [
      applications: [:logger],
      mod: { ExOsc, [] }
    ]
  end

  defp deps do
    []
  end
end
