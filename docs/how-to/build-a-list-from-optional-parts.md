# Build a list from optional parts

This guide shows how to build a list where some parts are optional. Such a
list is a list of class names for a web page, or a list of messages. A part
is optional when it depends on a condition, or when its value can be `nil`.
The examples use an alias:

```elixir
alias Shoddy.Lists
```

## Add an element only for a condition

Use `Shoddy.Lists.wrap_when/2`. It returns a list of one element for a
truthy condition, and an empty list for a falsy condition. Join the parts
with `++/2`:

```elixir
colored? = true
image = nil

["tree"] ++ Lists.wrap_when("tree-colored", colored?) ++ Lists.wrap_when("tree-media", image)
#=> ["tree", "tree-colored"]
```

Each part replaces `if condition, do: [element], else: []`.

## Add an element at the end of a list for a condition

Join the list and the result of `Shoddy.Lists.wrap_when/2`:

```elixir
colors = ["red", "blue"]
highlight = "gold"

colors ++ Lists.wrap_when(highlight, highlight != nil)
#=> ["red", "blue", "gold"]
```

## Remove the parts that are nil

Use `Shoddy.Lists.compact/1` when an absent part is `nil`. It removes each
`nil`, and it keeps `false`:

```elixir
size = nil

[size, "RGB", "8 bit"] |> Lists.compact() |> Enum.join(", ")
#=> "RGB, 8 bit"
```

`Shoddy.Maps.compact/1` and `Shoddy.Keywords.compact/1` do the same for the
values of a map and of a keyword list.

## Get an optional field from each record

Use `Shoddy.Lists.map_present/2`. It maps the list, and it removes each
result that is `nil`:

```elixir
users = [%{email: "ada@example.com"}, %{email: nil}, %{email: "grace@example.com"}]

Lists.map_present(users, & &1.email)
#=> ["ada@example.com", "grace@example.com"]
```

To remove the values that occur more than one time, call `Enum.uniq/1` on
the result.

## Collect the messages of a validation

Put the parts into one list, and flatten the list:

```elixir
items = []
total = 5

List.flatten([
  Lists.wrap_when("the order needs at least one item", items == []),
  Lists.wrap_when("the total cannot be negative", total < 0)
])
#=> ["the order needs at least one item"]
```

## Build iodata with an optional part

Iodata is a string, or a list of strings and of other iodata. Functions
such as `IO.puts/1` accept it. An empty list is correct iodata, so the
result of `Shoddy.Lists.wrap_when/2` can be a part of it:

```elixir
admin? = true

IO.iodata_to_binary(["Ada", Lists.wrap_when(" (admin)", admin?)])
#=> "Ada (admin)"
```

[The design of Shoddy](../explanation/design.md#a-list-from-optional-parts)
tells why `Shoddy.Lists.wrap_when/2` takes the element as its first
argument.
