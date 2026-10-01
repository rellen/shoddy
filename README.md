# Shoddy

Shoddy is an Elixir library of small functions for tasks that occur
frequently in Elixir code. Each function takes the value first, so it can be
a step of a pipeline. The library has no runtime dependencies.

This example builds a map from the parameters of a web form. The map gets
no entry for an absent email address, and it gets a default language:

```elixir
params = %{"name" => "Ada", "email" => nil}

%{}
|> Shoddy.Maps.put_if(:name, params["name"])
|> Shoddy.Maps.put_if(:email, params["email"])
|> Map.put(:language, Shoddy.coalesce([params["language"]], default: "en"))
#=> %{name: "Ada", language: "en"}
```

## The modules

- `Shoddy` applies a function to a value only if a condition is true or
  only if the value is not `nil`. It also selects the first value from a
  list of sources.
- `Shoddy.Maps` puts a value into a map only if the value is truthy, or only
  if the value is not `nil`. It reads a value with a default for `nil`. It
  also takes keys from a map with new names, and it merges nested maps.
- `Shoddy.Keywords` puts and reads a value in a keyword list in the same
  way, for example in the options of a function call.
- `Shoddy.MapSets` toggles the membership of an element in a map set.
- `Shoddy.Lists` finds the elements that occur more than one time in a list,
  or that have the same key. It also gets the only element of a list, and
  it makes a map from the key of each element to the element.
- `Shoddy.Strings` has a guard that rejects `nil` and an empty string
  together. It also changes an empty string to `nil`. It shortens a string
  for display.
- `Shoddy.Parse` converts text, such as user input, into an integer or into
  an allowed atom. It returns a result.
- `Shoddy.Result` operates on an ok tuple and on an error tuple in a
  pipeline.
- `Shoddy.Tagging` puts a value into a tagged tuple, such as the return
  value of a GenServer callback.
- `Shoddy.DateTimes` operates on dates and times. It extends the precision
  of a time value. It also rounds a time value down or up to a minute, an
  hour or a day.

## Installation

Shoddy is not on Hex. Add Shoddy from GitHub to the list of dependencies in
`mix.exs`:

```elixir
defp deps do
  [
    {:shoddy, github: "rellen/shoddy"}
  ]
end
```

## Documentation

The site https://rellen.github.io/shoddy/ has the documentation of each
module and each document below.

To learn the library, start with the tutorial:

- [Get started with Shoddy](docs/tutorials/get-started.md)

For one task, use a how-to guide:

- [Transform an optional value](docs/how-to/transform-an-optional-value.md)
- [Build a map from optional data](docs/how-to/build-a-map-from-optional-data.md)
- [Merge nested maps](docs/how-to/merge-nested-maps.md)
- [Build a keyword list of options](docs/how-to/build-a-keyword-list-of-options.md)
- [Choose the first available value](docs/how-to/choose-the-first-available-value.md)
- [Treat an empty string as no value](docs/how-to/treat-an-empty-string-as-no-value.md)
- [Shorten a string for display](docs/how-to/shorten-a-string-for-display.md)
- [Parse user input](docs/how-to/parse-user-input.md)
- [Chain operations that can fail](docs/how-to/chain-operations-that-can-fail.md)
- [Return a tagged tuple from a callback](docs/how-to/return-a-tagged-tuple-from-a-callback.md)
- [Toggle elements in a selection](docs/how-to/toggle-elements-in-a-selection.md)
- [Find duplicates in a list](docs/how-to/find-duplicates-in-a-list.md)
- [Index a list by a key](docs/how-to/index-a-list-by-a-key.md)
- [Get the only element of a list](docs/how-to/get-the-only-element-of-a-list.md)
- [Compare time values of different precision](docs/how-to/compare-time-values-of-different-precision.md)
- [Round a time value down](docs/how-to/round-a-time-value-down.md)
- [Round a time value up](docs/how-to/round-a-time-value-up.md)

For the rules that apply to each function, read the reference:

- [The conventions of the functions](docs/reference/conventions.md)

For the reasons behind the design, read the explanation:

- [The design of Shoddy](docs/explanation/design.md)

## Development

[Development](docs/development.md) tells how to get the tools, run the
checks and add a document. `CLAUDE.md` gives the rules for a commit message
and for prose.

## License

Apache 2.0
