# Compare time values of different precision

This guide shows how to compare two time values with `==` when their
precision is different. The precision is the count of digits after the
decimal point of the second. The precision is part of the struct. Thus `==`
can return `false` for two values of the same point in time:

```elixir
from_api = ~U[2024-01-01 00:00:00Z]
from_database = ~U[2024-01-01 00:00:00.000000Z]

from_api == from_database
#=> false
```

The examples below use an alias:

```elixir
alias Shoddy.DateTimes
```

## Compare two values

Use `Shoddy.DateTimes.extend_precision/2` to give each value a precision of
6 digits:

```elixir
DateTimes.extend_precision(from_api) == DateTimes.extend_precision(from_database)
#=> true
```

`Shoddy.DateTimes.extend_precision/2` never lowers the precision, so you can
give it each value. A value that already has 6 digits stays with no change.

If you need only the order of two values, use `DateTime.compare/2`. It
ignores the precision:

```elixir
DateTime.compare(from_api, from_database)
#=> :eq
```

## Remove duplicates from a list

`Enum.uniq/1` compares with the same rule as `==`. Extend the precision of
each value first:

```elixir
[from_api, from_database]
|> Enum.map(&DateTimes.extend_precision/1)
|> Enum.uniq()
#=> [~U[2024-01-01 00:00:00.000000Z]]
```

## Prepare a value for an Ecto field

Ecto raises `ArgumentError` when it writes a value to a field of the type
`:utc_datetime_usec` and the precision of the value is not 6. A value from
`DateTime.utc_now(:second)` has a precision of 0. Extend its precision:

```elixir
DateTime.utc_now(:second)
|> DateTimes.extend_precision()
```

## Extend the precision to milliseconds

Give `:millisecond` as the second argument:

```elixir
DateTimes.extend_precision(~U[2024-01-01 12:30:00Z], :millisecond)
#=> ~U[2024-01-01 12:30:00.000Z]
```

To lower the precision, use `DateTime.truncate/2`:

```elixir
DateTime.truncate(~U[2024-01-01 12:30:00.123456Z], :millisecond)
#=> ~U[2024-01-01 12:30:00.123Z]
```

`Shoddy.DateTimes.extend_precision/2` also accepts a `NaiveDateTime` and a
`Time`.
