# Sort and group records for display

This guide shows how to put a list of records into an order and into groups.
Examples are a table and a list with headings. Use
`Shoddy.Lists.sort_by_keys/2` and `Shoddy.Lists.group_by_in_order/2`. The
examples use an alias and this list:

```elixir
alias Shoddy.Lists

messages = [
  %{on: ~D[2024-03-02], from: "Grace", text: "Lunch?"},
  %{on: ~D[2024-03-01], from: "Ada", text: "Hello"},
  %{on: ~D[2024-03-02], from: "Ada", text: "Yes"}
]
```

## Sort by more than one key

Give a list of keys. The function compares by the second key only if the
values of the first key are equal:

```elixir
Lists.sort_by_keys(messages, [& &1.from, & &1.text])
#=> [
#=>   %{on: ~D[2024-03-01], from: "Ada", text: "Hello"},
#=>   %{on: ~D[2024-03-02], from: "Ada", text: "Yes"},
#=>   %{on: ~D[2024-03-02], from: "Grace", text: "Lunch?"}
#=> ]
```

## Give each key its own direction

Write the key as `{:asc, fun}` or `{:desc, fun}`. This example puts the
newest date first, and sorts the names of each date from A to Z:

```elixir
Lists.sort_by_keys(messages, [{:desc, & &1.on, Date}, {:asc, & &1.from}])
#=> [
#=>   %{on: ~D[2024-03-02], from: "Ada", text: "Yes"},
#=>   %{on: ~D[2024-03-02], from: "Grace", text: "Lunch?"},
#=>   %{on: ~D[2024-03-01], from: "Ada", text: "Hello"}
#=> ]
```

## Sort by a date or a time

Give the module as the third element of the key, such as `Date`, `Time` or
`DateTime`. The function then compares with `compare/2` of that module. The
operators `<` and `>` compare the fields of a struct, and they give a wrong
order:

```elixir
Enum.sort_by([~D[2024-02-01], ~D[2024-01-31]], & &1)
#=> [~D[2024-02-01], ~D[2024-01-31]]

Lists.sort_by_keys([~D[2024-02-01], ~D[2024-01-31]], [{:asc, & &1, Date}])
#=> [~D[2024-01-31], ~D[2024-02-01]]
```

## Put the records into groups under headings

Sort the records first, and then put them into groups. The groups keep the
order of the sorted list:

```elixir
messages
|> Lists.sort_by_keys([{:desc, & &1.on, Date}])
|> Lists.group_by_in_order(& &1.on)
|> Enum.map(fn {day, group} -> {day, Enum.map(group, & &1.text)} end)
#=> [{~D[2024-03-02], ["Lunch?", "Yes"]}, {~D[2024-03-01], ["Hello"]}]
```

`Enum.group_by/2` returns a map. A map has no order that you can use, so
the headings could change their order.

## Check that a list is in order

Use `Shoddy.Lists.sorted?/2`, for example for data that must arrive in order.
It takes the same sorters as `Enum.sort/2`, and it stops at the first pair
in the wrong order:

```elixir
Lists.sorted?([~D[2024-01-31], ~D[2024-02-01]], {:asc, Date})
#=> true

Lists.sorted?([3, 1, 2])
#=> false
```
