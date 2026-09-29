# Get started with Shoddy

In this tutorial, you make a small Elixir project that uses Shoddy. The
project builds a user profile from the parameters of a web form. A parameter
can be absent, so the code must handle a `nil` value.

You use five functions of Shoddy. Some of them examine whether a value is
truthy. A truthy value is a value that is not `nil` and not `false`.

- `Shoddy.then_if/2` applies a function to a truthy value.
- `Shoddy.Maps.put_if/3` puts a value into a map only if the value is
  truthy.
- `Shoddy.coalesce/2` returns the first value that is not `nil`.
- `Shoddy.Result.from_nil/2` and `Shoddy.Result.map_ok/2` operate on an ok
  tuple and on an error tuple.

You need Elixir 1.19 or a later version, and git.

## Make the project

Mix is the build tool of Elixir. Make a new project with Mix:

```sh
mix new profile
cd profile
```

Hex is the package manager of Elixir. Shoddy is not on Hex. Open `mix.exs`
and add Shoddy from GitHub to the list of dependencies:

```elixir
defp deps do
  [
    {:shoddy, github: "rellen/shoddy"}
  ]
end
```

Get the dependency:

```sh
mix deps.get
```

## Try the functions in IEx

IEx is the interactive shell of Elixir. Start IEx with the project:

```sh
iex -S mix
```

The function `Shoddy.then_if/2` calls the function only if the value is
truthy. Type these two lines:

```elixir
iex> Shoddy.then_if("  Ada ", &String.trim/1)
"Ada"
iex> Shoddy.then_if(nil, &String.trim/1)
nil
```

`String.trim(nil)` raises an error. `Shoddy.then_if/2` does not call the
function, so there is no error.

The function `Shoddy.Maps.put_if/3` puts a value into a map only if the
value is truthy:

```elixir
iex> Shoddy.Maps.put_if(%{name: "Ada"}, :email, "ada@example.com")
%{name: "Ada", email: "ada@example.com"}
iex> Shoddy.Maps.put_if(%{name: "Ada"}, :email, nil)
%{name: "Ada"}
```

The second map has no `:email` key. It does not have the entry
`email: nil`.

The function `Shoddy.coalesce/2` returns the first value that is not `nil`.
The option `:default` gives the value for a list that has no such value:

```elixir
iex> Shoddy.coalesce([nil, "fr", "en"])
"fr"
iex> Shoddy.coalesce([nil, nil], default: "en")
"en"
```

The function `Shoddy.Result.from_nil/2` puts a value into an ok tuple. For
`nil`, it returns an error tuple with the reason that you give:

```elixir
iex> Shoddy.Result.from_nil("Ada", :no_name)
{:ok, "Ada"}
iex> Shoddy.Result.from_nil(nil, :no_name)
{:error, :no_name}
```

The function `Shoddy.Result.map_ok/2` applies a function to the value in an
ok tuple. It returns an error tuple with no change:

```elixir
iex> Shoddy.Result.from_nil("Ada", :no_name) |> Shoddy.Result.map_ok(&String.upcase/1)
{:ok, "ADA"}
```

Stop IEx. Press Ctrl+C two times.

## Write the module

Replace the contents of `lib/profile.ex` with this module:

```elixir
defmodule Profile do
  alias Shoddy.Maps
  alias Shoddy.Result

  def build(params) do
    params["name"]
    |> Result.from_nil(:no_name)
    |> Result.map_ok(fn name ->
      %{name: String.trim(name)}
      |> Maps.put_if(:email, params["email"])
      |> Map.put(:language, Shoddy.coalesce([params["language"], "en"]))
    end)
  end
end
```

The function `build/1` does these steps:

1. It gets the name. If the name is absent, the function returns
   `{:error, :no_name}` and does no more steps.
2. It makes a map with the name, and it removes the spaces at the two ends.
3. It puts the email address into the map only if the address is present.
4. It puts the language into the map. If the language is absent, the
   language is `"en"`.

## Run the module

Start IEx again with `iex -S mix`. Call `Profile.build/1` with three
different sets of parameters:

```elixir
iex> Profile.build(%{"name" => " Ada ", "email" => "ada@example.com"})
{:ok, %{name: "Ada", language: "en", email: "ada@example.com"}}
iex> Profile.build(%{"name" => "Grace", "language" => "fr"})
{:ok, %{name: "Grace", language: "fr"}}
iex> Profile.build(%{"email" => "nobody@example.com"})
{:error, :no_name}
```

IEx can show the keys of a map in a different order. The order of the keys
does not change the map.

## Next steps

You made a project that uses Shoddy, and you used five of its functions.

- The how-to guides give the steps for one task each. For example,
  [Chain operations that can fail](../how-to/chain-operations-that-can-fail.md)
  shows more of `Shoddy.Result`.
- [The conventions of the functions](../reference/conventions.md) gives the rules
  that apply to each function.
- [The design of Shoddy](../explanation/design.md) tells why the functions
  behave as they do.
