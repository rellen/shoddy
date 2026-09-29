# Shoddy

Shoddy is an Elixir library. It contains small functions for tasks that
occur frequently in Elixir code.

```elixir
params = %{"name" => "Ada", "email" => nil}

%{}
|> Shoddy.Maps.put_if(:name, params["name"])
|> Shoddy.Maps.put_if(:email, params["email"])
|> Map.put(:language, Shoddy.coalesce([params["language"], "en"]))
#=> %{name: "Ada", language: "en"}
```

The library has no runtime dependencies.

## Installation

Hex is the package manager of Elixir. Shoddy is not on Hex. Add Shoddy from
GitHub to the list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:shoddy, github: "rellen/shoddy"}
  ]
end
```

## Documents

https://rellen.github.io/shoddy/ shows the documentation of the last push to
`main`. The documents follow Diátaxis. Diátaxis is a method that puts each
document into one of four types.

A tutorial is a lesson for a new user:

- [Get started with Shoddy](docs/tutorials/get-started.md)

A how-to guide gives the steps of one task:

- [Build a map from optional data](docs/how-to/build-a-map-from-optional-data.md)
- [Choose the first available value](docs/how-to/choose-the-first-available-value.md)
- [Chain operations that can fail](docs/how-to/chain-operations-that-can-fail.md)
- [Return values from callbacks](docs/how-to/return-values-from-callbacks.md)
- [Toggle elements in a selection](docs/how-to/toggle-elements-in-a-selection.md)
- [Compare time values of different precision](docs/how-to/compare-time-values.md)

A reference page gives the facts. The page of each module on the site is
also a reference.

- [The conventions of the functions](docs/reference/conventions.md)

An explanation gives the design and its reasons:

- [The design of Shoddy](docs/explanation/design.md)

For a contributor:

- [Development](docs/development.md) tells how to get the tools, run the
  checks and add a document.
- `CLAUDE.md` gives the rules for a commit message and for prose.

## License

Apache 2.0
