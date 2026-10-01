# Find duplicates in a list

This guide shows how to find the elements that occur more than one time in a
list. Use `Shoddy.Lists.duplicates/1` to get these elements. Use
`Shoddy.Lists.has_duplicates?/1` if you need only to know that such an
element exists. Use `Shoddy.Lists.duplicates_by/2` to find the elements that
have the same value in a field. The examples use an alias:

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

## Find the duplicate values of a field

To find the values that occur in a field of more than one record, take the
field from each record first:

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

## Find the records that have the same value in a field

`Shoddy.Lists.duplicates_by/2` returns the records, not only the values. The
result is a map from each duplicate value to its records, in the order of the
list:

```elixir
Lists.duplicates_by(users, & &1.email)
#=> %{
#=>   "ada@example.com" => [
#=>     %{name: "Ada", email: "ada@example.com"},
#=>     %{name: "A. Lovelace", email: "ada@example.com"}
#=>   ]
#=> }
```

The function can calculate the key. This example finds the names that are
equal if you ignore the case of the letters:

```elixir
Lists.duplicates_by(["Ada", "Grace", "ADA"], &String.downcase/1)
#=> %{"ada" => ["Ada", "ADA"]}
```

The result is an empty map if no two records have the same value. The
pattern `%{}` matches each map, so use `map_size/1` to examine the result:

```elixir
case Lists.duplicates_by(users, & &1.email) do
  duplicates when map_size(duplicates) == 0 -> {:ok, users}
  duplicates -> {:error, {:duplicate_emails, Map.keys(duplicates)}}
end
#=> {:error, {:duplicate_emails, ["ada@example.com"]}}
```

## Check that each record has the same value in a field

Use `Shoddy.Lists.all_same_by?/2`, for example for the items of an order,
which must have one currency:

```elixir
items = [%{price: 5, currency: :eur}, %{price: 7, currency: :usd}]

Lists.all_same_by?(items, & &1.currency)
#=> false
```

The function returns `true` for an empty list.

## Find time values that are equal but have a different precision

The functions compare elements and keys with the strict equality operator
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
