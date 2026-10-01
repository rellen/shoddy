# Parse user input

This guide shows how to convert text from a user, such as the parameters of
a web request, into a value. Use the functions of `Shoddy.Parse`. Each
function returns `{:ok, value}` or `{:error, reason}`. The examples use an
alias:

```elixir
alias Shoddy.Parse
```

## Read an integer

`Shoddy.Parse.integer/2` accepts only text that is a full integer:

```elixir
Parse.integer("25")
#=> {:ok, 25}

Parse.integer("25 items")
#=> {:error, :not_an_integer}
```

`Integer.parse/1` is different. It returns the start of the text as an
integer, and it returns the remaining text. Thus a check on `{value, _rest}`
accepts `"25 items"`.

## Accept only a range of integers

Give the options `:min` and `:max`. The reason of the error tells which
limit failed:

```elixir
Parse.integer("0", min: 1, max: 100)
#=> {:error, :too_small}

Parse.integer("500", min: 1, max: 100)
#=> {:error, :too_large}
```

## Use a default for a missing or incorrect value

Give the result to `Shoddy.Result.unwrap/2`. For each error, it returns the
default:

```elixir
params = %{"page" => "abc"}

params
|> Map.get("page", "")
|> Parse.integer(min: 1)
|> Shoddy.Result.unwrap(1)
#=> 1
```

## Read a number with a fractional part

Use `Shoddy.Parse.float/2`. It takes the options `:min` and `:max` too:

```elixir
Parse.float("2.5", min: 0, max: 5)
#=> {:ok, 2.5}

Parse.float("2.5 kg")
#=> {:error, :not_a_float}
```

For money, do not use a float, because a float cannot store each decimal
fraction exactly. Use a library for decimal numbers.

## Read a yes-or-no value

Use `Shoddy.Parse.boolean/2`. By default, it accepts only `"true"` and
`"false"`:

```elixir
Parse.boolean("true")
#=> {:ok, true}

Parse.boolean("yes")
#=> {:error, :not_a_boolean}
```

Give the options `:true_values` and `:false_values` for other texts:

```elixir
Parse.boolean("on", true_values: ["on"], false_values: ["off"])
#=> {:ok, true}
```

## Accept only a list of words

Use `Shoddy.Parse.one_of/2` for a value such as a sort direction. It
returns an atom from the list that you give:

```elixir
Parse.one_of("desc", [:asc, :desc])
#=> {:ok, :desc}

Parse.one_of("random", [:asc, :desc])
#=> {:error, :not_allowed}
```

Do not call `String.to_atom/1` on user input. The runtime never removes an
atom, and the number of atoms has a limit. `Shoddy.Parse.one_of/2` never
makes a new atom.

## Give each error a message for the user

Use `Shoddy.Result.map_error/2` to change each reason into a message:

```elixir
"0"
|> Parse.integer(min: 1, max: 10)
|> Shoddy.Result.map_error(fn
  :not_an_integer -> "Enter a number."
  :too_small -> "Enter 1 or more."
  :too_large -> "Enter 10 or less."
end)
#=> {:error, "Enter 1 or more."}
```

## Require some parameters

Use `Shoddy.Maps.fetch_keys/2`. It returns the required parameters, or the
parameters that are absent:

```elixir
Shoddy.Maps.fetch_keys(%{"email" => "ada@example.com"}, ["email", "password"])
#=> {:error, {:missing_keys, ["password"]}}

Shoddy.Maps.fetch_keys(%{"email" => "ada@example.com", "password" => "x"}, ["email"])
#=> {:ok, %{"email" => "ada@example.com"}}
```

The result contains only the given keys. `Map.take/2` returns the same map,
but it ignores an absent key, so you cannot tell that it is absent.

## Read a list of values

Use `Shoddy.Strings.split_trim/2` for a list in one field, such as tags. It
trims each value, and it removes each empty value:

```elixir
Shoddy.Strings.split_trim("elixir, otp, ,beam,")
#=> ["elixir", "otp", "beam"]
```

Give the separator as the second argument. Then give each value to a
function of `Shoddy.Parse`, and combine the results:

```elixir
"3; 1; 2"
|> Shoddy.Strings.split_trim(";")
|> Enum.map(&Parse.integer/1)
|> Shoddy.Result.collect()
#=> {:ok, [3, 1, 2]}
```

## Accept spaces around the value

The functions do not trim the text. Call `String.trim/1` first:

```elixir
" 42 "
|> String.trim()
|> Parse.integer()
#=> {:ok, 42}
```

[The design of Shoddy](../explanation/design.md#why-parse-examines-the-full-text)
tells why the functions examine the full text.
