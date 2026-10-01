# Chain operations that can fail

This guide shows how to connect operations that return an ok tuple or an
error tuple. The functions of `Shoddy.Result` give the value of an ok tuple
to the next operation. They pass an error tuple to the end of the pipeline
with no change.

The examples read an age from the parameters of a web form. They use this
function. For text that is not a correct age, it returns an error tuple.
The reason contains the text, so the caller can tell which input failed:

```elixir
def parse_age(text) do
  case Integer.parse(text) do
    {age, ""} when age >= 0 -> {:ok, age}
    _other -> {:error, {text, :invalid_age}}
  end
end
```

For the choice between a pipeline and `with`, see
[The design of Shoddy](../explanation/design.md#pipelines-and-with).

## Start from a value that can be nil

Use `Shoddy.Result.from_nil/2`. It puts a value that is not `nil` into an ok
tuple. For `nil`, it returns an error tuple with the reason that you give:

```elixir
params = %{"age" => "36"}

Shoddy.Result.from_nil(params["age"], :no_age)
#=> {:ok, "36"}
```

## Call an operation that can fail

Use `Shoddy.Result.then_ok/2`. The operation must return an ok tuple or an
error tuple:

```elixir
params
|> Map.get("age")
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
```

| `params` | Result |
| --- | --- |
| `%{"age" => "36"}` | `{:ok, 36}` |
| `%{"age" => "old"}` | `{:error, {"old", :invalid_age}}` |
| `%{}` | `{:error, :no_age}` |

## Call an operation that cannot fail

Use `Shoddy.Result.map_ok/2`. It puts the return value of the operation into
an ok tuple:

```elixir
params
|> Map.get("age")
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
|> Shoddy.Result.map_ok(&(&1 + 1))
```

For `%{"age" => "36"}`, the result is `{:ok, 37}`.

Do not give an operation that can fail to `Shoddy.Result.map_ok/2`. The
result is then a result inside a result, such as `{:ok, {:ok, 36}}`. If other
code gives you such a value, use `Shoddy.Result.flatten/1`:

```elixir
{:ok, {:ok, 36}}
|> Shoddy.Result.flatten()
#=> {:ok, 36}
```

## Check a condition

Use `Shoddy.Result.ensure/3` with `Shoddy.Result.then_ok/2`. It returns an
ok tuple if the predicate returns a truthy value, and an error tuple with
the reason that you give otherwise:

```elixir
params
|> Map.get("age")
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
|> Shoddy.Result.then_ok(&Shoddy.Result.ensure(&1, fn age -> age >= 18 end, :too_young))
```

| `params` | Result |
| --- | --- |
| `%{"age" => "41"}` | `{:ok, 41}` |
| `%{"age" => "12"}` | `{:error, :too_young}` |

## Change the reason of an error

Use `Shoddy.Result.map_error/2`. For example, change each reason to a
message for the user:

```elixir
{:error, {"old", :invalid_age}}
|> Shoddy.Result.map_error(fn
  :no_age -> "Enter your age."
  {text, :invalid_age} -> "The age #{inspect(text)} is not a number."
end)
#=> {:error, "The age \"old\" is not a number."}
```

## Recover from an error

Use `Shoddy.Result.recover/2`. It calls the function with the error as it
is, and the function returns a new result. An ok result goes to the end of
the pipeline with no change.

This example uses a stored age if the form has no age. It returns each other
error with no change, so a bad input still fails. A bare `:error` also stays
a bare `:error`:

```elixir
stored_age = 36

params
|> Map.get("age")
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
|> Shoddy.Result.recover(fn
  {:error, :no_age} -> {:ok, stored_age}
  error -> error
end)
```

| `params` | Result |
| --- | --- |
| `%{"age" => "41"}` | `{:ok, 41}` |
| `%{}` | `{:ok, 36}` |
| `%{"age" => "old"}` | `{:error, {"old", :invalid_age}}` |

## Write a log message for an error

Use `Shoddy.Result.tap_error/2`. It calls the function with the reason, and
it returns the result with no change:

```elixir
require Logger

{:error, {"old", :invalid_age}}
|> Shoddy.Result.tap_error(fn reason ->
  Logger.warning("cannot read the age: #{inspect(reason)}")
end)
#=> {:error, {"old", :invalid_age}}
```

`Shoddy.Result.tap_ok/2` does the same for the value of an ok tuple.

## Get the value at the end of the pipeline

Use `Shoddy.Result.unwrap/2`. It returns the value of an ok tuple, or the
default that you give for an error:

```elixir
Shoddy.Result.unwrap({:ok, 37}, 0)
#=> 37

Shoddy.Result.unwrap({:error, {"old", :invalid_age}}, 0)
#=> 0
```

If an error is a defect in the program, use `Shoddy.Result.unwrap!/1`. It
raises `ArgumentError` for an error.

## Select a result in a function head

Require the module, and use the guards `Shoddy.Result.is_ok/1` and
`Shoddy.Result.is_error/1`:

```elixir
require Shoddy.Result

def status(result) when Shoddy.Result.is_ok(result), do: 200
def status(result) when Shoddy.Result.is_error(result), do: 422
```

## Count or select the results in a list

Give `Shoddy.Result.ok?/1` or `Shoddy.Result.error?/1` to a function of
`Enum`:

```elixir
results = Enum.map(["36", "old", "7"], &parse_age/1)

Enum.count(results, &Shoddy.Result.ok?/1)
#=> 2

Enum.filter(results, &Shoddy.Result.error?/1)
#=> [error: {"old", :invalid_age}]
```

## Combine the results of a list

Use `Shoddy.Result.collect/2`. By default, it returns the values of the list
in an ok tuple, or the first error:

```elixir
["41", "5"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect()
#=> {:ok, [41, 5]}

["41", "old", "5", "-1"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect()
#=> {:error, {"old", :invalid_age}}
```

The option `:on_error` changes what the function does for an error. The
sections below show each value.

## Stop the work at the first error

`Enum.map/2` parses each element, also after the first error. To stop at the
first error, use `Stream.map/2`. `Shoddy.Result.collect/2` reads no element
after the first error, so the stream does not parse `"5"` and `"-1"`:

```elixir
["41", "old", "5", "-1"]
|> Stream.map(&parse_age/1)
|> Shoddy.Result.collect()
#=> {:error, {"old", :invalid_age}}
```

This applies only to the default `on_error: :halt`. With `:skip` or
`:accumulate`, `Shoddy.Result.collect/2` reads each element.

## Keep the values and skip the errors

Give `on_error: :skip`. The function ignores each error:

```elixir
["41", "old", "5", "-1"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect(on_error: :skip)
#=> {:ok, [41, 5]}
```

## Report each error of a list

Give `on_error: :accumulate`. If the list contains an error, the function
returns the reason of each error:

```elixir
["41", "old", "5", "-1"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect(on_error: :accumulate)
#=> {:error, [{"old", :invalid_age}, {"-1", :invalid_age}]}
```

## Decide what to do for each error

Give a function of arity 1. The function receives each error with no
change, and it returns one of these values:

- `{:cont, value}` puts `value` into the list, and `Shoddy.Result.collect/2`
  continues.
- `:skip` ignores the error, and `Shoddy.Result.collect/2` continues.
- `{:halt, error}` stops `Shoddy.Result.collect/2`, and the function returns
  `error`. The value `error` must be an error result.

This example writes a log message for each error and skips it:

```elixir
require Logger

["41", "old", "5", "-1"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect(
  on_error: fn error ->
    Logger.warning("cannot read an age: #{inspect(error)}")
    :skip
  end
)
#=> {:ok, [41, 5]}
```

This example puts 0 into the list for each error:

```elixir
["41", "old", "5"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect(on_error: fn _error -> {:cont, 0} end)
#=> {:ok, [41, 0, 5]}
```

## Check each field of a form

Put the result of each field into a map, and give the map to
`Shoddy.Result.collect_map/1`. It returns each error, not only the first:

```elixir
%{name: {:ok, "Ada"}, age: parse_age("old"), email: {:error, :missing}}
|> Shoddy.Result.collect_map()
#=> {:error, %{age: {"old", :invalid_age}, email: :missing}}

%{name: {:ok, "Ada"}, age: parse_age("36")}
|> Shoddy.Result.collect_map()
#=> {:ok, %{name: "Ada", age: 36}}
```

The map of errors has the same keys as the fields, so you can show each
error next to its field.

## Turn an exception into an error

Some functions raise an exception for a wrong input, such as
`String.to_existing_atom/1`. Use `Shoddy.Result.attempt/2`, and give the
exceptions to rescue:

```elixir
Shoddy.Result.attempt(fn -> String.to_existing_atom("no_such_atom_xyz") end, rescue: [ArgumentError])
|> Shoddy.Result.map_error(fn _exception -> :unknown_name end)
#=> {:error, :unknown_name}
```

An exception that is not in the list continues, so a defect stays visible.

## Accumulate a value with an operation that can fail

If each step needs the result of the step before it, use
`Shoddy.Result.reduce_ok/3`. It stops at the first error. This example adds
the ages, and it stops at the first incorrect age:

```elixir
add_age = fn text, total -> text |> parse_age() |> Shoddy.Result.map_ok(&(total + &1)) end

Shoddy.Result.reduce_ok(["41", "5"], 0, add_age)
#=> {:ok, 46}

Shoddy.Result.reduce_ok(["41", "old", "5"], 0, add_age)
#=> {:error, {"old", :invalid_age}}
```

`Shoddy.Result.collect/2` returns a list of the values. Use it if each step
is independent of the other steps.
