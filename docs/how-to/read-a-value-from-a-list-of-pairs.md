# Read a value from a list of pairs

This guide shows how to read one value from a list of pairs. A pair is a
tuple of two elements: a key and a value. Some libraries return such a list
with string keys, for example the attributes of an HTML element or the
headers of an HTTP request. Use `Shoddy.Lists.key_get/3`. The examples use
an alias and this list:

```elixir
alias Shoddy.Lists

attributes = [{"href", "/orders"}, {"class", "button"}]
```

## Read the value of a key

Give the list and the key. The function returns the value of the first
pair with the key:

```elixir
Lists.key_get(attributes, "href")
#=> "/orders"
```

## Use a default for an absent key

Without a default, the function returns `nil` for a key that is not in the
list. Give the default as the third argument:

```elixir
Lists.key_get(attributes, "title")
#=> nil

Lists.key_get(attributes, "title", "")
#=> ""
```

`List.keyfind/3` returns the pair, so the code then needs a `case` to get
the value or the default.

## Read a header of a request

The headers of a Plug connection are a list of pairs. The name of each
header is in lower case:

```elixir
headers = [{"accept", "text/html"}, {"x-request-id", "f3a9"}]

Lists.key_get(headers, "x-request-id")
#=> "f3a9"
```

## Read a keyword list

A keyword list is a list of pairs with atom keys, so
`Shoddy.Lists.key_get/3` reads it too. But `Keyword.get/3` is the usual
function for it. To get the default also for the value `nil`, use
`Shoddy.Keywords.get_present/3`.

[The design of Shoddy](../explanation/design.md#keyword-lists-in-a-separate-module)
tells why the function for a list of pairs is in `Shoddy.Lists`.
