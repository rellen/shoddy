# Compare time values of different precision

This guide shows how to compare two time values with `==` when their
precision is different. The precision is the count of digits after the
decimal point of the second. It is part of the struct, so two values of the
same point in time can be unequal.

```elixir
a = ~U[2024-01-01 00:00:00Z]
b = ~U[2024-01-01 00:00:00.000000Z]

a == b
#=> false
```

## Compare two values

Use `Shoddy.Hourglass.extend/2` on the value with the lower precision. The
default precision is `:microsecond`, which is 6 digits:

```elixir
Shoddy.Hourglass.extend(a) == b
#=> true
```

If you only need the order of two values, use `DateTime.compare/2`. It
ignores the precision:

```elixir
DateTime.compare(a, b)
#=> :eq
```

## Remove duplicates from a list

`Enum.uniq/1` compares with the same rule as `==`. Extend each value first:

```elixir
[a, b]
|> Enum.map(&Shoddy.Hourglass.extend/1)
|> Enum.uniq()
#=> [~U[2024-01-01 00:00:00.000000Z]]
```

## Prepare a value for a database column

A column of the type `:utc_datetime_usec` needs a precision of 6. A value
from `DateTime.utc_now(:second)` has a precision of 0. Extend it:

```elixir
DateTime.utc_now(:second) |> Shoddy.Hourglass.extend()
```

## Extend to milliseconds

Give `:millisecond` as the second argument:

```elixir
Shoddy.Hourglass.extend(~U[2024-01-01 12:30:00Z], :millisecond)
#=> ~U[2024-01-01 12:30:00.000Z]
```

The function never lowers the precision. A value with 6 digits keeps 6
digits. To lower the precision, use `DateTime.truncate/2`:

```elixir
DateTime.truncate(~U[2024-01-01 12:30:00.123456Z], :millisecond)
#=> ~U[2024-01-01 12:30:00.123Z]
```

The function also accepts a `NaiveDateTime` and a `Time`.
