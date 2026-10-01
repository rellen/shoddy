# Change the entries of a map

This guide shows how to remove, rename, count and compare the entries of a
map. The examples use an alias:

```elixir
alias Shoddy.Maps
```

## Remove the entries with nil

Use `Shoddy.Maps.compact/1`, for example before you send the map to an API
that treats `null` and an absent field in different ways. It keeps `false`:

```elixir
Maps.compact(%{name: "Ada", email: nil, admin: false})
#=> %{name: "Ada", admin: false}
```

## Give a key a new name

Use `Shoddy.Maps.rename_key/3`. The other entries stay:

```elixir
Maps.rename_key(%{mail: "ada@example.com", name: "Ada"}, :mail, :email)
#=> %{email: "ada@example.com", name: "Ada"}
```

If the new key is already in the map, the function raises `ArgumentError`,
because one value would go.

## Count with a map

Use `Shoddy.Maps.increment/3` in a reduction. The first count of a key is
the amount:

```elixir
["apple", "pear", "apple"]
|> Enum.reduce(%{}, &Maps.increment(&2, &1))
#=> %{"apple" => 2, "pear" => 1}
```

To count each element of a list in one step, `Enum.frequencies/1` does the
same work. Use `Shoddy.Maps.increment/3` when the counts change at
different places, for example in the state of a process.

## Find a key by its value

Use `Shoddy.Maps.invert/1`. It swaps the keys and the values:

```elixir
roles = %{admin: 1, editor: 2}

Maps.invert(roles)[2]
#=> :editor
```

If two keys have the same value, the function raises `ArgumentError`.

## Send a map with string keys

Use `Shoddy.Maps.stringify_keys/1`. It converts the keys at the top level
only:

```elixir
Maps.stringify_keys(%{name: "Ada", address: %{city: "London"}})
#=> %{"name" => "Ada", "address" => %{city: "London"}}
```

## Compare two versions of a map

Use `Shoddy.Maps.diff/2`, for example for a log of changes:

```elixir
before = %{name: "Ada", role: :user, age: 36}
after_change = %{name: "Ada", role: :admin, email: "ada@example.com"}

Maps.diff(before, after_change)
#=> %{added: %{email: "ada@example.com"}, removed: %{age: 36}, changed: %{role: {:user, :admin}}}
```

The function compares only the top level. A nested map that changes is one
changed value.
