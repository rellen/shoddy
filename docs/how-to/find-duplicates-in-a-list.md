# Find duplicates in a list

This guide shows how to find the elements that occur more than one time in a
list. Use `Shoddy.Lists.duplicates/1` to get these elements. Use
`Shoddy.Lists.has_duplicates?/1` if you need only to know that such an
element exists. The examples use an alias:

```elixir
alias Shoddy.Lists
```

## Report the duplicates of a list

`Shoddy.Lists.duplicates/1` returns each duplicate one time, in the order of
its first occurrence:

```elixir
emails = ["ada@example.com", "grace@example.com", "ada@example.com", "ada@example.com"]

Lists.duplicates(emails)
#=> ["ada@example.com"]
```

Put the duplicates into an error tuple, and return the list in an ok tuple
if it has no duplicates:

```elixir
case Lists.duplicates(emails) do
  [] -> {:ok, emails}
  duplicates -> {:error, {:duplicate_emails, duplicates}}
end
#=> {:error, {:duplicate_emails, ["ada@example.com"]}}
```

Do not use `emails -- Enum.uniq(emails)` for this message. That expression
contains an element one time for each extra occurrence:

```elixir
emails -- Enum.uniq(emails)
#=> ["ada@example.com", "ada@example.com"]
```

## Check a list for duplicates

If you do not need the duplicates, use `Shoddy.Lists.has_duplicates?/1`. It
is faster than `Lists.duplicates(list) != []`, and it stops at a duplicate
near the start of the list:

```elixir
Lists.has_duplicates?(emails)
#=> true
```

Use it with `Shoddy.Result.ensure/3` to get a result:

```elixir
Shoddy.Result.ensure(emails, &(not Lists.has_duplicates?(&1)), :duplicate_emails)
#=> {:error, :duplicate_emails}
```

## Find the duplicates of a field

To find the records that have the same value in a field, take the field from
each record first:

```elixir
users = [
  %{name: "Ada", email: "ada@example.com"},
  %{name: "Grace", email: "grace@example.com"},
  %{name: "A. Lovelace", email: "ada@example.com"}
]

users
|> Enum.map(& &1.email)
|> Lists.duplicates()
#=> ["ada@example.com"]
```

## Find time values that are equal but have a different precision

The two functions compare elements with the strict equality operator
`===/2`. Two time values of the same point in time are different if their
precision is different:

```elixir
Lists.duplicates([~U[2024-01-01 00:00:00Z], ~U[2024-01-01 00:00:00.000000Z]])
#=> []
```

Give each value the same precision first:

```elixir
[~U[2024-01-01 00:00:00Z], ~U[2024-01-01 00:00:00.000000Z]]
|> Enum.map(&Shoddy.DateTimes.extend_precision/1)
|> Lists.duplicates()
#=> [~U[2024-01-01 00:00:00.000000Z]]
```

[Compare time values of different precision](compare-time-values-of-different-precision.md)
tells more about the precision. For the same reason, the integer `1` and the
float `1.0` are two different elements.
