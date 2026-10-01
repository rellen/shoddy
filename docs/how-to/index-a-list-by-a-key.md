# Index a list by a key

This guide shows how to make a map from a list of records, so that you can
find each record by its key. Use `Shoddy.Lists.index_by/2`. The examples use
an alias and this list:

```elixir
alias Shoddy.Lists

users = [
  %{id: 1, name: "Ada"},
  %{id: 2, name: "Grace"},
  %{id: 3, name: "Alan"}
]
```

## Find records by their ID

Make the map one time. Then each lookup is fast:

```elixir
by_id = Lists.index_by(users, & &1.id)

by_id[2]
#=> %{id: 2, name: "Grace"}
```

`Enum.find/2` reads the list from the start for each lookup. For many
lookups in a long list, the map is faster.

## Join two lists by a key

Index one list, and then read the other list:

```elixir
orders = [%{user_id: 3, total: 12}, %{user_id: 1, total: 30}]
by_id = Lists.index_by(users, & &1.id)

Enum.map(orders, &{by_id[&1.user_id].name, &1.total})
#=> [{"Alan", 12}, {"Ada", 30}]
```

## Find an error in data that must have unique keys

`Shoddy.Lists.index_by/2` raises `ArgumentError` if more than one record has
the same key. The message tells each such key:

```elixir
Lists.index_by([%{id: 1}, %{id: 2}, %{id: 1}], & &1.id)
#=> ** (ArgumentError) more than one element has the same key: [1]
```

`Map.new(users, &{&1.id, &1})` keeps the last of these records, and it does
not tell you about the others.

## Keep each record of a key that is not unique

If more than one record can have the same key, do not use
`Shoddy.Lists.index_by/2`. Use `Enum.group_by/2`. It returns a list of
records for each key:

```elixir
Enum.group_by([%{id: 1, v: :a}, %{id: 1, v: :b}], & &1.id)
#=> %{1 => [%{id: 1, v: :a}, %{id: 1, v: :b}]}
```

To find only the keys that are not unique, use
`Shoddy.Lists.duplicates_by/2`. See
[Find duplicates in a list](find-duplicates-in-a-list.md).
