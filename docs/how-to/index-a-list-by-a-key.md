# Index a list by a key

This guide shows how to make a map from a list of records, so that you can
find each record by its key. Use `Shoddy.Lists.index_by/3`. The examples use
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

## Map each key to one field

Give the option `:value`. It is a function that returns the value for a
record:

```elixir
Lists.index_by(users, & &1.id, value: & &1.name)
#=> %{1 => "Ada", 2 => "Grace", 3 => "Alan"}
```

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
`Shoddy.Lists.index_by/3`. A `nil` key never matches, so an order with no user
gets `nil`, also if the second list contains a new user with no ID yet:

```elixir
Lists.join_by([%{user_id: nil}], [%{id: nil, name: "Draft"}], & &1.user_id, & &1.id)
#=> [{%{user_id: nil}, nil}]
```

## Join each record to all its partners in a second list

Use `Shoddy.Lists.group_join_by/4` when one record of the first list can
have many partners, such as each user and the orders of that user:

```elixir
orders = [%{user_id: 3, total: 12}, %{user_id: 1, total: 30}, %{user_id: 3, total: 5}]

Lists.group_join_by(users, orders, & &1.id, & &1.user_id)
#=> [
#=>   {%{id: 1, name: "Ada"}, [%{user_id: 1, total: 30}]},
#=>   {%{id: 2, name: "Grace"}, []},
#=>   {%{id: 3, name: "Alan"}, [%{user_id: 3, total: 12}, %{user_id: 3, total: 5}]}
#=> ]
```

A record with no partner gets an empty list. Each list of partners keeps
the order of the second list. A `nil` key never matches, as for
`Shoddy.Lists.join_by/4`.

## Find an error in data that must have unique keys

`Shoddy.Lists.index_by/3` raises `ArgumentError` if more than one record has
the same key. The message tells each such key:

```elixir
Lists.index_by([%{id: 1}, %{id: 2}, %{id: 1}], & &1.id)
#=> ** (ArgumentError) more than one element has the same key: [1]
```

`Map.new(users, &{&1.id, &1})` keeps the last of these records, and it does
not tell you about the others.

## Keep one record of a key that is not unique

Give the option `:on_duplicate` if the data can contain a key more than one
time, and the code must not raise. The value `:first` keeps the first
record of the key, and `:last` keeps the last record:

```elixir
rows = [%{email: "ada@example.com", id: 1}, %{email: "ada@example.com", id: 7}]

Lists.index_by(rows, & &1.email, on_duplicate: :first)
#=> %{"ada@example.com" => %{email: "ada@example.com", id: 1}}

Lists.index_by(rows, & &1.email, on_duplicate: :last, value: & &1.id)
#=> %{"ada@example.com" => 7}
```

Use this option only when a duplicate is correct data, or when the code
must continue with data that has an error. An example is a page where a
person corrects that error. The default, `:raise`, shows a duplicate at
once.

## Keep each record of a key that is not unique

To keep each record of such a key, do not use `Shoddy.Lists.index_by/3`.
Use `Enum.group_by/2`. It returns a list of records for each key:

```elixir
Enum.group_by([%{id: 1, v: :a}, %{id: 1, v: :b}], & &1.id)
#=> %{1 => [%{id: 1, v: :a}, %{id: 1, v: :b}]}
```

To find only the keys that are not unique, use
`Shoddy.Lists.duplicates_by/2`. See
[Find duplicates in a list](find-duplicates-in-a-list.md).
