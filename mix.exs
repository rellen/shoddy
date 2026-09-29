defmodule Shoddy.MixProject do
  use Mix.Project

  def project do
    [
      app: :shoddy,
      version: "0.2.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: "Small functions for tasks that occur frequently in Elixir code.",
      dialyzer: [plt_local_path: "priv/plts"]
    ]
  end

  def cli do
    [preferred_envs: ["test.mutation": :test]]
  end

  defp aliases do
    [
      # Tell git to use the tracked hooks directory. Do not copy the file into
      # .git/hooks, because a copy does not change when a person changes the
      # tracked file.
      # Mix runs this command without a shell, so the command must be one
      # command with no operator.
      "hook.install": [
        "cmd git config core.hooksPath hooks"
      ],
      # Run mutation testing with muex. The command mix check does not run
      # this alias, so a mutation result cannot make a check fail. The option
      # --fail-at 0 stops a low score from making this alias fail. Each module
      # is small, and the default filter of muex skips a small module, so
      # --no-filter is necessary.
      "test.mutation": [
        "muex --no-filter --fail-at 0 --timeout 30000"
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:quokka, "~> 2.12", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.23.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.16.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40.1", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:muex, "~> 0.11", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14.1", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
