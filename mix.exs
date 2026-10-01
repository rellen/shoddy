defmodule Shoddy.MixProject do
  use Mix.Project

  def project do
    [
      app: :shoddy,
      version: "0.3.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: "Small functions for tasks that occur frequently in Elixir code.",
      name: "Shoddy",
      source_url: "https://github.com/rellen/shoddy",
      homepage_url: "https://rellen.github.io/shoddy/",
      docs: docs(),
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

  # The pages of `mix docs`. The groups follow Diátaxis. A tutorial is a
  # lesson, a how-to guide gives the steps of one task, a reference page gives
  # the facts, and an explanation gives the design and its reasons. The page of
  # each module is also a reference. See `docs/development.md`.
  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "docs/tutorials/get-started.md",
        "docs/how-to/transform-an-optional-value.md",
        "docs/how-to/build-a-map-from-optional-data.md",
        "docs/how-to/merge-nested-maps.md",
        "docs/how-to/build-a-keyword-list-of-options.md",
        "docs/how-to/choose-the-first-available-value.md",
        "docs/how-to/chain-operations-that-can-fail.md",
        "docs/how-to/return-a-tagged-tuple-from-a-callback.md",
        "docs/how-to/toggle-elements-in-a-selection.md",
        "docs/how-to/find-duplicates-in-a-list.md",
        "docs/how-to/get-the-only-element-of-a-list.md",
        "docs/how-to/compare-time-values-of-different-precision.md",
        "docs/how-to/round-a-time-value-down.md",
        "docs/reference/conventions.md",
        "docs/explanation/design.md",
        "docs/development.md"
      ],
      groups_for_extras: [
        Tutorials: ~r"docs/tutorials/",
        "How-to guides": ~r"docs/how-to/",
        Reference: ~r"docs/reference/",
        Explanation: ~r"docs/explanation/",
        Development: ["docs/development.md"]
      ],
      groups_for_modules: [
        Values: [Shoddy],
        Collections: [Shoddy.Maps, Shoddy.Keywords, Shoddy.MapSets, Shoddy.Lists],
        "Results and tagged tuples": [Shoddy.Result, Shoddy.Tagging],
        "Dates and times": [Shoddy.DateTimes]
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
