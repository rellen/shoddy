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

Use `Shoddy.Lists.join_by/4`. It puts each element of the first list with
the element of the second list that has the same key:

```elixir
orders = [%{user_id: 3, total: 12}, %{user_id: 9, total: 30}]

Lists.join_by(orders, users, & &1.user_id, & &1.id)
#=> [{%{user_id: 3, total: 12}, %{id: 3, name: "Alan"}}, {%{user_id: 9, total: 30}, nil}]
```

For a key with no partner, the second element of the tuple is `nil`. The
keys of the second list, other than `nil`, must be unique, as for
`Shoddy.Lists.index_by/2`. A `nil` key never matches, so an order with no user
gets `nil`, also if the second list contains a user that is not saved:

```elixir
Lists.join_by([%{user_id: nil}], [%{id: nil, name: "Draft"}], & &1.user_id, & &1.id)
#=> [{%{user_id: nil}, nil}]
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
