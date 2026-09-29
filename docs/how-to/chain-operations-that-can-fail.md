# Chain operations that can fail

This guide shows how to connect operations that return an ok tuple or an
error tuple. The functions of `Shoddy.Result` give the value of an ok tuple
to the next operation. They pass an error tuple to the end of the pipeline
with no change.

The examples read an age from the parameters of a web form. They use this
function, which returns an error tuple for text that is not a correct age:

```elixir
def parse_age(text) do
  case Integer.parse(text) do
    {age, ""} when age >= 0 -> {:ok, age}
    _other -> {:error, :invalid_age}
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
| `%{"age" => "old"}` | `{:error, :invalid_age}` |
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

## Change the reason of an error

Use `Shoddy.Result.map_error/2`. For example, change each reason to a
message for the user:

```elixir
{:error, :invalid_age}
|> Shoddy.Result.map_error(fn
  :no_age -> "Enter your age."
  :invalid_age -> "Enter your age as a number."
end)
#=> {:error, "Enter your age as a number."}
```

## Write a log message for an error

Use `Shoddy.Result.tap_error/2`. It calls the function with the reason, and
it returns the result with no change:

```elixir
require Logger

{:error, :invalid_age}
|> Shoddy.Result.tap_error(fn reason ->
  Logger.warning("cannot read the age: #{inspect(reason)}")
end)
#=> {:error, :invalid_age}
```

`Shoddy.Result.tap_ok/2` does the same for the value of an ok tuple.

## Get the value at the end of the pipeline

Use `Shoddy.Result.unwrap/2`. It returns the value of an ok tuple, or the
default that you give for an error:

```elixir
Shoddy.Result.unwrap({:ok, 37}, 0)
#=> 37

Shoddy.Result.unwrap({:error, :invalid_age}, 0)
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
#=> [error: :invalid_age]
```

## Combine the results of a list

Use `Shoddy.Result.collect/1`. It returns the values of the list in an ok
tuple, or the first error:

```elixir
["41", "5"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect()
#=> {:ok, [41, 5]}

["36", "old", "-1"]
|> Enum.map(&parse_age/1)
|> Shoddy.Result.collect()
#=> {:error, :invalid_age}
```

`Shoddy.Result.collect/1` stops at the first error. To report each error,
use `Enum.filter/2` with `Shoddy.Result.error?/1`, as the section above
shows.
