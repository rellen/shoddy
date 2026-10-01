# Calculate an average

This guide shows how to calculate the mean of a list of numbers, also for a
list that can be empty. Use `Shoddy.Numbers.mean/1`.

## Calculate the mean

The function returns the mean in an ok tuple. The mean is always a float:

```elixir
Shoddy.Numbers.mean([4, 5, 3])
#=> {:ok, 4.0}
```

## Handle an empty list

For an empty list, the function returns `{:error, :empty}`. The expression
`Enum.sum(list) / length(list)` raises `ArithmeticError` for the same list:

```elixir
Shoddy.Numbers.mean([])
#=> {:error, :empty}
```

Give the result to `Shoddy.Result.unwrap/2` for a default value:

```elixir
ratings = []

ratings
|> Shoddy.Numbers.mean()
|> Shoddy.Result.unwrap(nil)
#=> nil
```

## Show the mean with fewer digits

Round the float with `Float.round/2`:

```elixir
{:ok, mean} = Shoddy.Numbers.mean([4, 5, 5])

Float.round(mean, 1)
#=> 4.7
```
