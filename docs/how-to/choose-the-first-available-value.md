# Choose the first available value

This guide shows how to select one value from several sources.
`Shoddy.coalesce/2` examines a list of values in order. It returns the
first value that it does not reject.

For each option, see the documentation of `Shoddy.coalesce/2`.

## Use the first value that is not nil

Put the sources into a list, with the most important source first:

```elixir
user = %{nickname: nil, name: "Ada Lovelace"}

Shoddy.coalesce([user.nickname, user.name, "Anonymous"])
#=> "Ada Lovelace"
```

The last element of the list is a fixed value. The function thus always
finds a value.

## Reject more values than nil

By default, the function rejects only `nil`. An empty string is not `nil`,
so the function returns it:

```elixir
user = %{nickname: "", name: "Ada Lovelace"}

Shoddy.coalesce([user.nickname, user.name, "Anonymous"])
#=> ""
```

Give the option `:reject` to reject the empty string also:

```elixir
Shoddy.coalesce([user.nickname, user.name], reject: [nil, ""])
#=> "Ada Lovelace"
```

To reject `false` also, add it to the list:

```elixir
Shoddy.coalesce([nil, false, true], reject: [nil, false])
#=> true
```

## Give a value for the case with no match

Give the option `:default`. The function returns this value if it rejects
each value in the list:

```elixir
user = %{nickname: "", name: nil}

Shoddy.coalesce([user.nickname, user.name], reject: [nil, ""], default: "Anonymous")
#=> "Anonymous"
```

The function does not compare the default with the `:reject` list. Thus, with
`default: nil`, the function can return `nil`, although it rejects `nil` in
the list.

## Delay an expensive operation

Put the operation into a function of arity 0. The function calls it only if
it rejects each value before it:

```elixir
Shoddy.coalesce([
  System.get_env("GREETING"),
  fn -> File.read!("greeting.txt") end
])
```

If the variable `GREETING` has a value, the function does not read the file.

## Return a function as the value

Sometimes the value that you want is a function of arity 0, such as a
callback. Give `call_functions?: false`. The function then returns the
function and does not call it:

```elixir
opts = []

on_done = Shoddy.coalesce([opts[:on_done], fn -> :ok end], call_functions?: false)
is_function(on_done, 0)
#=> true
```

Without this option, the function calls `fn -> :ok end` and returns `:ok`.
