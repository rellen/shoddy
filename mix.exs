defmodule Quicksand.MixProject do
  use Mix.Project

  def project do
    [
      app: :quicksand,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A grab-bag of utility functions for Elixir."
    ]
  end

  defp deps do
    []
  end
end
