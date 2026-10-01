# Treat an empty string as no value

This guide shows how to treat `nil` and `""` as the same thing: no value. A
web form sends `""` for a field that the user did not fill in. `Shoddy.Strings`
has two tools for this case:

- The guard `Shoddy.Strings.is_non_empty_string/1` rejects `nil`, `""` and
  each value that is not a binary.
- The function `Shoddy.Strings.presence/1` changes `""` to `nil`. It returns
  each other value with no change.

The examples use an alias:

```elixir
alias Shoddy.Strings
```

## Accept only a string with content in a function clause

Import the guard, and put it in the clause. A second clause handles the
other values:

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

`Shoddy.Maps.put_present/3` ignores `nil`, but it puts `""` into the map.
Give it the result of `Shoddy.Strings.presence/1`:

```elixir
params = %{"name" => "Ada", "email" => "", "subscribed" => false}

%{}
|> Shoddy.Maps.put_present(:name, Strings.presence(params["name"]))
|> Shoddy.Maps.put_present(:email, Strings.presence(params["email"]))
|> Shoddy.Maps.put_present(:subscribed, Strings.presence(params["subscribed"]))
#=> %{name: "Ada", subscribed: false}
```

`Shoddy.Strings.presence/1` does not change `false` or a number. Thus the
map keeps a value that is not a string.

## Transform a field only if it has content

Give the result of `Shoddy.Strings.presence/1` to `Shoddy.then_present/3`.
The function then ignores `""`, and `String.to_integer/1` does not raise an
exception for it:

```elixir
""
|> Strings.presence()
|> Shoddy.then_present(&String.to_integer/1)
#=> nil

"36"
|> Strings.presence()
|> Shoddy.then_present(&String.to_integer/1)
#=> 36
```

## Remove the empty values from a list

Give the guard to `Enum.filter/2`. It also removes each value that is not a
string:

```elixir
require Shoddy.Strings

Enum.filter(["Ada", "", nil, "Grace"], &Strings.is_non_empty_string/1)
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

## Treat a string that contains only whitespace as empty

Whitespace is a character such as a space, a tab or a newline. The two
tools do not trim the string, so they keep `" "`. Call `String.trim/1`
first. `Shoddy.then_if/2` returns `nil` with no change:

```elixir
"  "
|> Shoddy.then_if(&String.trim/1)
|> Strings.presence()
#=> nil
```

To only check a value, use `Shoddy.Strings.blank?/1`. It returns `true` for
`nil`, `""` and a string that contains only whitespace:

```elixir
Strings.blank?("  ")
#=> true

Strings.blank?(" Ada ")
#=> false
```

[The design of Shoddy](../explanation/design.md#what-is_non_empty_string-accepts)
tells why the guard does not trim the string.
