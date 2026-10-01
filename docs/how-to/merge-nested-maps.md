# Merge nested maps

This guide shows how to merge two maps that contain maps, for example
settings and their defaults. `Map.merge/2` replaces a nested map completely.
`Shoddy.Maps.deep_merge/2` merges the nested maps too.

The examples use these defaults:

```elixir
defaults = %{
  log: %{level: :info, format: :text},
  http: %{port: 4000, timeout: 5_000}
}
```

## Change one nested value

Give only the values to change. The other values of the nested map stay:

```elixir
Shoddy.Maps.deep_merge(defaults, %{http: %{port: 8080}})
#=> %{log: %{level: :info, format: :text}, http: %{port: 8080, timeout: 5_000}}
```

`Map.merge/2` removes the timeout:

```elixir
Map.merge(defaults, %{http: %{port: 8080}})
#=> %{log: %{level: :info, format: :text}, http: %{port: 8080}}
```

## Merge more than two maps

Use `Enum.reduce/2`. Give the maps in order of priority, the lowest first.
The last map wins:

```elixir
env = %{log: %{level: :warning}}
user = %{log: %{format: :json}}

Enum.reduce([defaults, env, user], &Shoddy.Maps.deep_merge(&2, &1))
#=> %{log: %{level: :warning, format: :json}, http: %{port: 4000, timeout: 5_000}}
```

## Replace a nested map completely

`Shoddy.Maps.deep_merge/2` keeps each key of a nested map of the left side.
To replace a nested map, put it after the merge:

```elixir
defaults
|> Shoddy.Maps.deep_merge(%{http: %{port: 8080}})
|> Map.put(:log, %{level: :debug})
#=> %{log: %{level: :debug}, http: %{port: 8080, timeout: 5_000}}
```

## Put one value deep into a map

To set one value, use `Shoddy.Maps.put_path/3`. It makes each map on the
path that is absent:

```elixir
Shoddy.Maps.put_path(%{}, [:log, :level], :debug)
#=> %{log: %{level: :debug}}
```

`put_in/3` raises `ArgumentError` for the same call, because the map under
`:log` is absent. A value of `nil` on the path also becomes a map:

```elixir
Shoddy.Maps.put_path(%{log: nil}, [:log, :level], :debug)
#=> %{log: %{level: :debug}}
```

The function treats `nil` as absent. For another value on the path that is
not a map, such as `false`, it raises `ArgumentError`. Thus, to turn off a
group of settings that `Shoddy.Maps.put_path/3` must not change, use `false`
and not `nil`.

## Turn off a nested group of settings

A value that is not a map replaces the nested map. Use `nil` or `false`:

```elixir
Shoddy.Maps.deep_merge(defaults, %{log: false})
#=> %{log: false, http: %{port: 4000, timeout: 5_000}}
```

## Merge decoded JSON

The function accepts keys of each type. A map from a JSON decoder has
string keys:

```elixir
stored = %{"theme" => %{"color" => "blue", "font" => "serif"}}

Shoddy.Maps.deep_merge(stored, %{"theme" => %{"color" => "green"}})
#=> %{"theme" => %{"color" => "green", "font" => "serif"}}
```

## Merge a keyword list or a struct

The function does not merge a keyword list, a list or a struct. The value
of the right side replaces it:

```elixir
Shoddy.Maps.deep_merge(%{opts: [retries: 3, backoff: 100]}, %{opts: [retries: 5]})
#=> %{opts: [retries: 5]}
```

To merge them, use `Map.merge/3` with your own rule. This example merges
each keyword list with `Keyword.merge/2`:

```elixir
Map.merge(%{opts: [retries: 3, backoff: 100]}, %{opts: [retries: 5]}, fn
  _key, left, right when is_list(left) and is_list(right) -> Keyword.merge(left, right)
  _key, _left, right -> right
end)
#=> %{opts: [backoff: 100, retries: 5]}
```

[The design of Shoddy](../explanation/design.md#the-values-that-deep_merge-merges)
tells why the function merges only plain maps.
