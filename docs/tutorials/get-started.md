# Get started with Shoddy

In this tutorial, you make a small project that builds a user profile from
the parameters of a web form. A parameter can be absent, so the code must
handle `nil`. You use Shoddy for that work, and you write tests for the
result.

You use five functions:

- `Shoddy.then_if/2` applies a function to a value only if the value is
  truthy. A truthy value is a value that is not `nil` and not `false`.
- `Shoddy.Maps.put_if/3` puts a value into a map only if the value is
  truthy.
- `Shoddy.coalesce/2` returns the first value that is not `nil`.
- `Shoddy.Result.from_nil/2` puts a value into an ok tuple, or returns an
  error tuple for `nil`.
- `Shoddy.Result.map_ok/2` applies a function to the value in an ok tuple.

You need Elixir 1.19 or a later version.

## Make the project

Make a new project:

```sh
mix new profile
cd profile
```

Shoddy is not on Hex. Open `mix.exs`, and add Shoddy from GitHub to the list
of dependencies:

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

## Try the functions

Start IEx with the project:

```sh
iex -S mix
```

`Shoddy.then_if/2` calls the function only for a truthy value. For `nil`,
it returns `nil` and does not call the function:

```elixir
iex> Shoddy.then_if("  Ada ", &String.trim/1)
"Ada"
iex> Shoddy.then_if(nil, &String.trim/1)
nil
```

A direct call of `String.trim(nil)` raises `FunctionClauseError`.

`Shoddy.Maps.put_if/3` puts a value into a map only if the value is truthy:

```elixir
iex> Shoddy.Maps.put_if(%{name: "Ada"}, :email, "ada@example.com")
%{name: "Ada", email: "ada@example.com"}
iex> Shoddy.Maps.put_if(%{name: "Ada"}, :email, nil)
%{name: "Ada"}
```

The second map has no `:email` key. It does not contain `email: nil`.

`Shoddy.coalesce/2` returns the first value in the list that is not `nil`.
If each value is `nil`, it returns the value of the option `:default`:

```elixir
iex> Shoddy.coalesce([nil, "fr"])
"fr"
iex> Shoddy.coalesce([nil], default: "en")
"en"
```

`Shoddy.Result.from_nil/2` puts a value into an ok tuple. For `nil`, it
returns an error tuple with the reason that you give:

```elixir
iex> Shoddy.Result.from_nil("Ada", :no_name)
{:ok, "Ada"}
iex> Shoddy.Result.from_nil(nil, :no_name)
{:error, :no_name}
```

`Shoddy.Result.map_ok/2` applies a function to the value in an ok tuple. It
returns an error tuple with no change:

```elixir
iex> Shoddy.Result.map_ok({:ok, "Ada"}, &String.upcase/1)
{:ok, "ADA"}
iex> Shoddy.Result.map_ok({:error, :no_name}, &String.upcase/1)
{:error, :no_name}
```

Stop IEx with Ctrl+C two times.

## Write the module

Replace the contents of `lib/profile.ex` with this module:

```elixir
defmodule Profile do
  @moduledoc """
  Builds a user profile from the parameters of a web form.
  """

  alias Shoddy.Maps
  alias Shoddy.Result

  def build(params) do
    params["name"]
    |> Result.from_nil(:no_name)
    |> Result.map_ok(fn name ->
      %{name: String.trim(name)}
      |> Maps.put_if(:email, email(params))
      |> Map.put(:language, language(params))
    end)
  end

  defp email(params), do: Shoddy.then_if(params["email"], &String.downcase/1)

  defp language(params), do: Shoddy.coalesce([params["language"]], default: "en")
end
```

`build/1` does these steps:

1. If the name is absent, it returns `{:error, :no_name}`. It does no more
   steps.
2. It makes a map with the name, and it removes the spaces at the two ends
   of the name.
3. If the email address is present, it puts the address into the map in
   lowercase. If the address is absent, the map gets no `:email` key.
4. It puts the language into the map. If the language is absent, the
   language is `"en"`.

## Test the module

`mix new` made a test for a function that the module no longer has. Replace
the contents of `test/profile_test.exs` with these tests:

```elixir
defmodule ProfileTest do
  use ExUnit.Case

  test "build/1 removes the spaces at the two ends of the name" do
    assert Profile.build(%{"name" => " Ada "}) == {:ok, %{name: "Ada", language: "en"}}
  end

  test "build/1 puts the email address in lowercase" do
    params = %{"name" => "Ada", "email" => "Ada@Example.com"}

    assert Profile.build(params) ==
             {:ok, %{name: "Ada", email: "ada@example.com", language: "en"}}
  end

  test "build/1 keeps the language of the parameters" do
    assert Profile.build(%{"name" => "Grace", "language" => "fr"}) ==
             {:ok, %{name: "Grace", language: "fr"}}
  end

  test "build/1 returns an error if the name is absent" do
    assert Profile.build(%{"email" => "nobody@example.com"}) == {:error, :no_name}
  end
end
```

Run the tests:

```sh
mix test
```

The output shows `4 tests, 0 failures`.

## Next steps

You made a project that uses five functions of Shoddy, and you tested it.

- Each how-to guide gives the steps for one task.
  [Chain operations that can fail](../how-to/chain-operations-that-can-fail.md)
  shows more of `Shoddy.Result`.
- [Build a map from optional data](../how-to/build-a-map-from-optional-data.md)
  and [Build a keyword list of options](../how-to/build-a-keyword-list-of-options.md)
  show more of `Shoddy.Maps` and `Shoddy.Keywords`.
- [The conventions of the functions](../reference/conventions.md) gives the
  rules that apply to each function.
- [The design of Shoddy](../explanation/design.md) tells why the functions
  behave as they do.
