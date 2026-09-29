# Chain operations that can fail

This guide shows how to connect operations that return an ok tuple or an
error tuple. The functions of `Shoddy.Result` pass an ok tuple to the next
operation. They pass an error tuple to the end of the pipeline with no
change.

The examples use this function. It returns an ok tuple for a correct age
and an error tuple for all other text:

```elixir
def parse_age(text) do
  case Integer.parse(text) do
    {age, ""} when age >= 0 -> {:ok, age}
    _ -> {:error, :invalid_age}
  end
end
```

## Start from a value that can be nil

Use `Shoddy.Result.from_nil/2`. It puts a value that is not `nil` into an ok
tuple. For `nil`, it returns an error tuple with the reason that you give.

```elixir
Shoddy.Result.from_nil(params["age"], :no_age)
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

For `%{"age" => "36"}`, the result is `{:ok, 36}`. For
`%{"age" => "old"}`, the result is `{:error, :invalid_age}`. For `%{}`, the
result is `{:error, :no_age}`.

## Call an operation that cannot fail

Use `Shoddy.Result.map_ok/2`. The function puts the return value of the
operation into an ok tuple:

```elixir
params
|> Map.get("age")
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
|> Shoddy.Result.map_ok(&(&1 + 1))
```

For `%{"age" => "36"}`, the result is `{:ok, 37}`.

Do not give an operation that can fail to `Shoddy.Result.map_ok/2`. The
result is then a result inside a result, such as `{:ok, {:ok, 36}}`. If you
get such a value from other code, use `Shoddy.Result.flatten/1`:

```elixir
{:ok, "36"}
|> Shoddy.Result.map_ok(&parse_age/1)
|> Shoddy.Result.flatten()
#=> {:ok, 36}
```

## Change the reason of an error

Use `Shoddy.Result.map_error/2`. For example, change each reason to a
message for the user:

```elixir
result
|> Shoddy.Result.map_error(fn
  :no_age -> "The age is absent."
  :invalid_age -> "The age is not a number."
end)
```

## Write a log message for an error

Use `Shoddy.Result.tap_error/2`. It calls the function with the reason, and
it returns the result with no change:

```elixir
require Logger

result
|> Shoddy.Result.tap_error(&Logger.warning("no age: #{inspect(&1)}"))
```

`Shoddy.Result.tap_ok/2` does the same for the value of an ok tuple.

## Get the value at the end of the pipeline

Use `Shoddy.Result.unwrap/2` to get the value, or a default value for an
error:

```elixir
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

## Count or select results in a list

Use `Shoddy.Result.ok?/1` and `Shoddy.Result.error?/1` as the function for
`Enum`:

```elixir
results = Enum.map(["36", "old", "7"], &parse_age/1)

Enum.count(results, &Shoddy.Result.ok?/1)
#=> 2

Enum.filter(results, &Shoddy.Result.error?/1)
#=> [error: :invalid_age]
```
