# Treat an empty string as no value

This guide shows how to treat `nil` and `""` as the same thing: no value. A
web form sends `""` for a field that the user did not fill in. Use the guard
`Shoddy.Strings.is_non_empty_string/1`. It rejects `nil`, `""` and each
value that is not a binary. The examples import the guard:

```elixir
import Shoddy.Strings, only: [is_non_empty_string: 1]
```

## Accept only a string with content in a function clause

Put the guard in the clause. A second clause handles the other values:

```elixir
defmodule Greeting do
  import Shoddy.Strings, only: [is_non_empty_string: 1]

  def greet(name) when is_non_empty_string(name), do: "Hello, " <> name
  def greet(_name), do: "Hello"
end

Greeting.greet("Ada")
#=> "Hello, Ada"

Greeting.greet("")
#=> "Hello"
```

## Ignore an empty field when you build a map

`Shoddy.Maps.put_if/3` ignores `nil` and `false`, but it puts `""` into the
map, because `""` is truthy. Give it `is_non_empty_string(value) && value`.
For `nil` and `""`, this expression is `false`:

```elixir
params = %{"name" => "Ada", "email" => ""}

%{}
|> Shoddy.Maps.put_if(:name, is_non_empty_string(params["name"]) && params["name"])
|> Shoddy.Maps.put_if(:email, is_non_empty_string(params["email"]) && params["email"])
#=> %{name: "Ada"}
```

## Remove the empty values from a list

Give the guard to `Enum.filter/2`:

```elixir
Enum.filter(["Ada", "", nil, "Grace"], &is_non_empty_string/1)
#=> ["Ada", "Grace"]
```

## Choose the first value that is not empty

For a list of sources, use `Shoddy.coalesce/2` with the option `:reject`:

```elixir
Shoddy.coalesce([params["nickname"], "", "Ada"], reject: [nil, ""])
#=> "Ada"
```

[Choose the first available value](choose-the-first-available-value.md)
tells more about `Shoddy.coalesce/2`.

## Treat a string of spaces as empty

The guard does not trim the string, so it accepts `" "`. Trim the value
first with `Shoddy.then_if/2`, which ignores `nil`:

```elixir
name = Shoddy.then_if("  ", &String.trim/1)
#=> ""

is_non_empty_string(name)
#=> false
```

[The design of Shoddy](../explanation/design.md#what-is_non_empty_string-accepts)
tells why the guard does not trim the string.
