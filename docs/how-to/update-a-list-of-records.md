# Update a list of records

This guide shows how to apply a change to a list of records. An example is a
message that tells about a new or a changed record. The examples use an
alias and this list:

```elixir
alias Shoddy.Lists

users = [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
```

## Replace a record or add a new record

Use `Shoddy.Lists.upsert_by/4`. If a record has the same key, the function
puts the new record at its position. Otherwise, it adds the new record at the
end:

```elixir
Lists.upsert_by(users, & &1.id, %{id: 2, name: "Grace Hopper"})
#=> [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace Hopper"}]

Lists.upsert_by(users, & &1.id, %{id: 3, name: "Alan"})
#=> [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}, %{id: 3, name: "Alan"}]
```

## Add a new record at the start

Give the option `at: :start`, for example for a list with the newest record
first:

```elixir
Lists.upsert_by(users, & &1.id, %{id: 3, name: "Alan"}, at: :start)
#=> [%{id: 3, name: "Alan"}, %{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
```

## Change one field of a record

To change a field and keep the other fields, use `update_in/3` with
`Access.filter/1`. It changes each record that the function selects:

```elixir
update_in(users, [Access.filter(&(&1.id == 2)), :name], &String.upcase/1)
#=> [%{id: 1, name: "Ada"}, %{id: 2, name: "GRACE"}]
```

## Remove a record

Use `Enum.reject/2`:

```elixir
Enum.reject(users, &(&1.id == 1))
#=> [%{id: 2, name: "Grace"}]
```

## Move a record to a new position

Use `Shoddy.Lists.move/3`, for example after a user drags a record to a new
place. The indexes start at 0:

```elixir
Lists.move([:a, :b, :c, :d], 0, 2)
#=> [:b, :c, :a, :d]
```

For an index that is not in the list, the function raises `ArgumentError`.
