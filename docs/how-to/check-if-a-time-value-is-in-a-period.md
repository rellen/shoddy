# Check if a time value is in a period

This guide shows how to check if a date or a time is in a period. Use
`Shoddy.DateTimes.between?/3`. The period includes its first value and
excludes its last value. The examples use an alias:

```elixir
alias Shoddy.DateTimes
```

## Check if an event occurs on a day

Make the start of the day and the start of the next day. A value in the day
is not before the first value, and it is before the last value:

```elixir
event = ~U[2024-01-01 23:59:59Z]
start = DateTimes.floor(event, :day)
next_day = DateTimes.next_start(event, :day)

DateTimes.between?(event, start, next_day)
#=> true

DateTimes.between?(next_day, start, next_day)
#=> false
```

The next day starts at the last value, so the period excludes it. Thus two
days that follow each other never contain the same value.

## Check a date in a booking

A guest arrives on the first date and leaves on the last date. The guest
uses each night from the first date, but not the night of the last date:

```elixir
arrival = ~D[2024-07-01]
departure = ~D[2024-07-04]

DateTimes.between?(~D[2024-07-03], arrival, departure)
#=> true

DateTimes.between?(~D[2024-07-04], arrival, departure)
#=> false
```

`date in Date.range(arrival, departure)` is different. The range includes
the last date.

## Do not compare with the operators < and >

The operators compare the fields of two structs, not the points in time.
The result is often wrong:

```elixir
~D[2024-02-01] < ~D[2024-01-31]
#=> true

DateTimes.between?(~D[2024-02-01], ~D[2024-01-01], ~D[2024-01-31])
#=> false
```

## Check if two periods overlap

Use `Shoddy.DateTimes.overlap?/2`. Give each period as a tuple
`{first, last}`. Two periods that only touch do not overlap:

```elixir
booked = {~D[2024-07-01], ~D[2024-07-04]}

DateTimes.overlap?(booked, {~D[2024-07-04], ~D[2024-07-06]})
#=> false

DateTimes.overlap?(booked, {~D[2024-07-03], ~D[2024-07-05]})
#=> true
```

The first booking ends on the morning of 4 July, and the second booking
starts on that day. Thus the room is free for the second booking.

## Check values in different time zones

The three values can be a `DateTime` in different time zones. The function
compares the points in time. Values in the same time zone are easier to
read, so the examples on this page use UTC.

## Select the values in a period

Give the function to `Enum.filter/2`:

```elixir
events = [~D[2024-06-30], ~D[2024-07-02], ~D[2024-07-04]]

Enum.filter(events, &DateTimes.between?(&1, ~D[2024-07-01], ~D[2024-07-04]))
#=> [~D[2024-07-02]]
```

[The design of Shoddy](../explanation/design.md#why-between-excludes-the-last-value)
tells why the period excludes its last value.
