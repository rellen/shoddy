# Round a time value up

This guide shows how to round a time value up to the start of the next
minute, hour or day. Use `Shoddy.DateTimes.ceil/2`. The examples use an
alias:

```elixir
alias Shoddy.DateTimes
```

## Find the next start of an hour

Give the current time and the unit:

```elixir
DateTimes.ceil(~U[2024-01-01 12:34:56Z], :hour)
#=> ~U[2024-01-01 13:00:00Z]
```

A value that is already at the start of an hour stays the same:

```elixir
DateTimes.ceil(~U[2024-01-01 13:00:00Z], :hour)
#=> ~U[2024-01-01 13:00:00Z]
```

Thus a job that runs each hour can get its next run time from
`DateTimes.ceil(DateTime.utc_now(), :hour)`. At the start of an hour, the
next run time is the current time.

## Set an expiry time at the start of an hour

Add the minimum life first, and then round up. The value expires at the
start of an hour, and never before the minimum life ends:

```elixir
~U[2024-01-01 12:34:56Z]
|> DateTime.add(30, :minute)
|> DateTimes.ceil(:hour)
#=> ~U[2024-01-01 14:00:00Z]
```

## Find the end of the unit that contains a value

Do not use `Shoddy.DateTimes.ceil/2` for the end of a period. For a value
at the start of a unit, it returns the value, so the start and the end of
the period are equal:

```elixir
start = DateTimes.floor(~U[2024-01-01 00:00:00Z], :day)
#=> ~U[2024-01-01 00:00:00Z]

DateTimes.ceil(~U[2024-01-01 00:00:00Z], :day)
#=> ~U[2024-01-01 00:00:00Z]
```

Add one unit to the start instead:

```elixir
DateTime.add(start, 1, :day)
#=> ~U[2024-01-02 00:00:00Z]
```

Use the start and the end as a range that includes the start and excludes
the end. Each value of that day is in the range.

## Round a value in a local time zone

`Shoddy.DateTimes.ceil/2` accepts a `DateTime` only in UTC, as
`Shoddy.DateTimes.floor/2` does. Convert the value to UTC with
`DateTime.shift_zone/2`, or to the local wall time with
`DateTime.to_naive/1`, first.
[Round a time value down](round-a-time-value-down.md#round-a-value-in-a-local-time-zone)
tells the difference.

## Round a Time up

The function does not accept a `Time`. Near the end of the day, the next
unit does not exist. `Time.add/3` would go back to midnight, so the result
would be before the value.

If you know that the result is in the same day, put the time on any date.
Then take the time from the result:

```elixir
~D[2000-01-01]
|> NaiveDateTime.new!(~T[10:15:00])
|> DateTimes.ceil(:hour)
|> NaiveDateTime.to_time()
#=> ~T[11:00:00]
```
