# Get the only element of a list

This guide shows how to get the element of a list that must contain exactly
one element. Use `Shoddy.Lists.single/1`. It returns an error tuple for an
empty list and for a list of more than one element. The examples use an
alias:

```elixir
alias Shoddy.Lists
```

## Get the element

`Shoddy.Lists.single/1` puts the element into an ok tuple:

```elixir
Lists.single(["ada@example.com"])
#=> {:ok, "ada@example.com"}
```

For an empty list, the reason is `:empty`. For more than one element, the
reason contains the number of elements:

```elixir
Lists.single([])
#=> {:error, :empty}

Lists.single(["ada@example.com", "grace@example.com"])
#=> {:error, {:many, 2}}
```

## Find the one record that matches a condition

Filter the list, and then give the result to `Shoddy.Lists.single/1`.
`List.first/1` is different: it ignores a second record that matches, and it
returns `nil` if no record matches.

```elixir
users = [
  %{id: 1, email: "ada@example.com"},
  %{id: 2, email: "grace@example.com"},
  %{id: 3, email: "ada@example.com"}
]

users
|> Enum.filter(&(&1.email == "grace@example.com"))
|> Lists.single()
#=> {:ok, %{id: 2, email: "grace@example.com"}}

users
|> Enum.filter(&(&1.email == "ada@example.com"))
|> Lists.single()
#=> {:error, {:many, 2}}
```

## Give each error a reason of your domain

Use `Shoddy.Result.map_error/2` to change the reason. The function does not
change an ok tuple:

```elixir
users
|> Enum.filter(&(&1.email == "alan@example.com"))
|> Lists.single()
|> Shoddy.Result.map_error(fn
  :empty -> :not_found
  {:many, _count} -> :ambiguous_email
end)
#=> {:error, :not_found}
```

## Use the element in the next operation

`Shoddy.Lists.single/1` returns a result. Thus the functions of
`Shoddy.Result` can continue the pipeline:

```elixir
users
|> Enum.filter(&(&1.email == "grace@example.com"))
|> Lists.single()
|> Shoddy.Result.map_ok(& &1.id)
#=> {:ok, 2}
```

[Chain operations that can fail](chain-operations-that-can-fail.md) tells
more about these functions.
