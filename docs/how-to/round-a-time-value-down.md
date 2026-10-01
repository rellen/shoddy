# Round a time value down

This guide shows how to round a time value down to the start of a minute,
an hour or a day. Use `Shoddy.DateTimes.floor/2`. To round a value up, see
[Round a time value up](round-a-time-value-up.md). The examples use an alias:

```elixir
alias Shoddy.DateTimes
```

## Put events into groups by the hour

Give `Shoddy.DateTimes.floor/2` to `Enum.group_by/2`:

```elixir
events = [
  ~U[2024-01-01 09:15:00Z],
  ~U[2024-01-01 09:45:00Z],
  ~U[2024-01-01 10:05:00Z]
]

Enum.group_by(events, &DateTimes.floor(&1, :hour))
#=> %{
#=>   ~U[2024-01-01 09:00:00Z] => [~U[2024-01-01 09:15:00Z], ~U[2024-01-01 09:45:00Z]],
#=>   ~U[2024-01-01 10:00:00Z] => [~U[2024-01-01 10:05:00Z]]
#=> }
```

For groups by the minute or by the day, give `:minute` or `:day`.

## Find the start of the current day

Round the current time down to the day:

```elixir
DateTime.utc_now()
|> DateTimes.floor(:day)
```

The result is midnight in UTC. Use it as the start of a query for the
events of today.

## Round a value in a local time zone

`Shoddy.DateTimes.floor/2` accepts a `DateTime` only in UTC. For a value in
another time zone, select one of these methods:

- To round in UTC, convert the value with `DateTime.shift_zone/2` first.
- To round the local wall time, convert the value with
  `DateTime.to_naive/1` first. The wall time is the time that a clock in
  that time zone shows. The result has no time zone.

```elixir
local
|> DateTime.to_naive()
|> DateTimes.floor(:day)
```

The two methods can return different days. In this example, `local` is
`#DateTime<2024-01-02 00:30:00+01:00 CET Europe/Paris>`. The local wall time
rounds down to `~N[2024-01-02 00:00:00]`. The same moment in UTC is
`~U[2024-01-01 23:30:00Z]`, and it rounds down to
`~U[2024-01-01 00:00:00Z]`.

[The design of Shoddy](../explanation/design.md#why-floor-accepts-only-utc)
tells the reason for this rule.

## Show the hours with no events

`Enum.group_by/2` gives no group for an hour with no event. Use
`Shoddy.DateTimes.stream/3` to make each hour of the period, and add a count
of 0 for each hour with no group:

```elixir
counts =
  [~U[2024-01-01 09:15:00Z], ~U[2024-01-01 11:05:00Z]]
  |> Enum.frequencies_by(&DateTimes.floor(&1, :hour))

~U[2024-01-01 09:00:00Z]
|> DateTimes.stream(~U[2024-01-01 12:00:00Z], :hour)
|> Enum.map(&{&1.hour, Map.get(counts, &1, 0)})
#=> [{9, 1}, {10, 0}, {11, 1}]
```

The stream stops before the last value, so the period from 09:00 to 12:00
has three hours.
