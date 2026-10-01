# Transform the keys and values of a map

This guide shows how to change each value or each key of a map. Use
`Shoddy.Maps.map_values/2` and `Shoddy.Maps.map_keys/2`. The examples use an
alias:

```elixir
alias Shoddy.Maps
```

## Change each value

Give a function that receives the value. The keys stay the same:

```elixir
prices = %{apple: 120, pear: 95}

Maps.map_values(prices, &(&1 / 100))
#=> %{apple: 1.2, pear: 0.95}
```

## Count the elements of each group

`Enum.group_by/2` returns a list for each key. Give `length/1` to
`Shoddy.Maps.map_values/2`:

```elixir
["apple", "avocado", "banana"]
|> Enum.group_by(&String.first/1)
|> Maps.map_values(&length/1)
#=> %{"a" => 2, "b" => 1}
```

## Change each key

Give a function that receives the key. The values stay the same:

```elixir
Maps.map_keys(%{name: "Ada", email: "ada@example.com"}, &Atom.to_string/1)
#=> %{"email" => "ada@example.com", "name" => "Ada"}
```

## Find keys that become the same key

If the function returns the same new key for two keys, one value would go.
`Shoddy.Maps.map_keys/2` raises `ArgumentError` instead, and the message
tells the keys:

```elixir
Maps.map_keys(%{"Email" => "a@example.com", "email" => "b@example.com"}, &String.downcase/1)
#=> ** (ArgumentError) more than one key has the same new key: "email" for the keys ["Email", "email"]
```

`Map.new(map, fn {k, v} -> {String.downcase(k), v} end)` keeps one of the
two values, and it does not tell you about the other.

## Use the key to change the value

The two functions receive only the key or only the value. If the change
needs both, use `Map.new/2`:

```elixir
Map.new(%{a: 1, b: 2}, fn {key, value} -> {key, "#{key}=#{value}"} end)
#=> %{a: "a=1", b: "b=2"}
```
