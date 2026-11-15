# Choose the first available value

This guide shows how to select one value from a list of sources, such as an
option of the user, a configuration value and a fixed default.
`Shoddy.coalesce/2` examines the list in order. It returns the first value
that it does not reject.

## Use the first value that is not nil

Put the sources into a list, with the most important source first:

```elixir
user = %{nickname: nil, name: "Ada Lovelace"}

Shoddy.coalesce([user.nickname, user.name])
#=> "Ada Lovelace"
```

## Give a default value

If `Shoddy.coalesce/2` rejects each value in the list, it returns the value
of the option `:default`. Without the option, it returns `nil`.

```elixir
user = %{nickname: nil, name: nil}

Shoddy.coalesce([user.nickname, user.name], default: "Anonymous")
#=> "Anonymous"
```

## Give a default for a key with the value nil

`Map.get/3` returns its default only for an absent key. For a key with the
value `nil`, it returns `nil`:

```elixir
element = %{name: "intro", tags: nil}

Map.get(element, :tags, [])
#=> nil
```

Use `Shoddy.Maps.get_present/3`. It returns the default for an absent key and
for `nil`:

```elixir
Shoddy.Maps.get_present(element, :tags, [])
#=> []
```

`Map.get(element, :tags) || []` returns the default also for `false`.
`Shoddy.Maps.get_present/3` returns `false` with no change. For a keyword
list, use `Shoddy.Keywords.get_present/3`:

```elixir
Shoddy.Keywords.get_present([retry: false], :retry, true)
#=> false
```

## Give a default for a value in a nested map

Use `Shoddy.Maps.get_path_present/3` with a list of keys. It returns the
default if a key of the path is absent, or if a value on the path is `nil`:

```elixir
settings = %{"intro" => %{order: 2}, "end" => %{order: nil}}

Shoddy.Maps.get_path_present(settings, ["end", :order], 0)
#=> 0
```

The function also reads a field of a struct on the path. `get_in/2` raises
an error for most structs.

## Find the keys that have a value

Use `Shoddy.Maps.present_keys/2` to find which optional fields have a
value. It returns each key with a value that is not `nil`, in the order of
the list:

```elixir
node = %{name: "intro", column: 2, order: nil}

Shoddy.Maps.present_keys(node, [:column, :order])
#=> [:column]
```

The function raises `KeyError` for a key that is not in the map.

## Reject more values than nil

By default, `Shoddy.coalesce/2` rejects only `nil`. An empty string is not
`nil`, so the function returns it:

```elixir
user = %{nickname: "", name: "Ada Lovelace"}

Shoddy.coalesce([user.nickname, user.name])
#=> ""
```

Give the option `:reject` with each value to reject:

```elixir
Shoddy.coalesce([user.nickname, user.name], reject: [nil, ""])
#=> "Ada Lovelace"
```

The option replaces the default list `[nil]`. Thus, to reject `nil` also,
keep `nil` in the list.

To test one value for `nil` and `""`, use the guard
`Shoddy.Strings.is_non_empty_string/1`. See
[Treat an empty string as no value](treat-an-empty-string-as-no-value.md).

## Delay an expensive source

Put the source into a function of arity 0. `Shoddy.coalesce/2` calls that
function only if it rejects each value before the function:

```elixir
Shoddy.coalesce([
  System.get_env("GREETING"),
  fn -> File.read!("greeting.txt") end
])
```

If the environment variable `GREETING` has a value, `Shoddy.coalesce/2`
does not read the file.

## Return a function as the value

Sometimes the value that you want is a function of arity 0, such as an
callback. Give `call_functions?: false`. `Shoddy.coalesce/2` then returns
the function and does not call it:

```elixir
opts = []

on_done = Shoddy.coalesce([opts[:on_done], fn -> :ok end], call_functions?: false)
is_function(on_done, 0)
#=> true
```

Without this option, `Shoddy.coalesce/2` calls `fn -> :ok end` and returns
`:ok`.
