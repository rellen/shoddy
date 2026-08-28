defmodule Quicksand.MixProject do
  use Mix.Project

  def project do
    [
      app: :quicksand,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: "Small functions for tasks that occur frequently in Elixir code.",
      dialyzer: [plt_local_path: "priv/plts"]
    ]
  end

  defp aliases do
    [
      # Point git at the tracked hooks directory. Do not copy the file into
      # .git/hooks. A copy becomes old when a person changes the tracked file.
      # Mix runs this command without a shell, so the command must be one
      # command with no operator.
      "hook.install": [
        "cmd git config core.hooksPath hooks"
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:quokka, "~> 2.12", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.22.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.16.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40.1", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14.1", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
