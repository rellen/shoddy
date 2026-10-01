# Round a time value up

This guide shows how to round a time value up to the start of a minute, an
hour or a day. Use `Shoddy.DateTimes.ceil/2`. A value at the start of a unit
stays the same. The examples use an alias:

```elixir
alias Shoddy.DateTimes
```

## Round up to the start of an hour

Give the time value and the unit:

```elixir
DateTimes.ceil(~U[2024-01-01 12:34:56Z], :hour)
#=> ~U[2024-01-01 13:00:00Z]
```

A value that is already at the start of an hour stays the same:

```elixir
DateTimes.ceil(~U[2024-01-01 13:00:00Z], :hour)
#=> ~U[2024-01-01 13:00:00Z]
```

## Set an expiry time at the start of an hour

Add the minimum life first, and then round up. The value expires at the
start of an hour, and never before the minimum life ends:

```elixir
~U[2024-01-01 12:34:56Z]
|> DateTime.add(30, :minute)
|> DateTimes.ceil(:hour)
#=> ~U[2024-01-01 14:00:00Z]
```

## Find the start of the next unit

Do not use `Shoddy.DateTimes.ceil/2` for the next run of a job each hour.
For a value at the start of a unit, it returns the value. A job that runs at
13:00:00 then gets 13:00:00 as its next run, and it runs again at once.

Use `Shoddy.DateTimes.next_start/2` instead. Its result is always after
the value:

```elixir
DateTimes.next_start(~U[2024-01-01 13:00:00Z], :hour)
#=> ~U[2024-01-01 14:00:00Z]
```

## Find the end of the unit that contains a value

Use `Shoddy.DateTimes.next_start/2` for the end of a period too. The result
of `Shoddy.DateTimes.floor/2` is the start:

```elixir
DateTimes.floor(~U[2024-01-01 00:00:00Z], :day)
#=> ~U[2024-01-01 00:00:00Z]

DateTimes.next_start(~U[2024-01-01 00:00:00Z], :day)
#=> ~U[2024-01-02 00:00:00Z]
```

`Shoddy.DateTimes.ceil/2` would return `~U[2024-01-01 00:00:00Z]` for this
value, so the start and the end would be equal.

Use the start and the end as a range that includes the start and excludes
the end. Each value of that day is in the range.

## Round to the nearest unit

Use `Shoddy.DateTimes.round/2`. A value at the middle of a unit rounds up:

```elixir
DateTimes.round(~U[2024-01-01 12:29:59Z], :hour)
#=> ~U[2024-01-01 12:00:00Z]

DateTimes.round(~U[2024-01-01 12:30:00Z], :hour)
#=> ~U[2024-01-01 13:00:00Z]
```

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
