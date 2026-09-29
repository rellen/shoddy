# Build a map from optional data

This guide shows how to build a map from data that can be absent. Data from
a web form often has this property. The map gets an entry only for a truthy
value. A truthy value is a value that is not `nil` and not `false`. The map
does not get an entry with the value `nil`.

For the rules that apply to each function, see
[The conventions of the functions](../reference/conventions.md).

## Put the truthy values

Start with an empty map. Call `Shoddy.Maps.put_if/3` one time for each
field:

```elixir
params = %{"name" => " Ada ", "email" => nil}

%{}
|> Shoddy.Maps.put_if(:name, params["name"])
|> Shoddy.Maps.put_if(:email, params["email"])
#=> %{name: " Ada "}
```

The function ignores `nil` and `false`. If the map already has an entry for
the key, that entry stays with no change.

## Change a value before you put it into the map

A function such as `String.trim/1` raises an error for `nil`. Use
`Shoddy.then_if/2` to call the function only for a truthy value:

```elixir
params = %{"name" => " Ada ", "email" => nil, "age" => "36"}

%{}
|> Shoddy.Maps.put_if(:name, Shoddy.then_if(params["name"], &String.trim/1))
|> Shoddy.Maps.put_if(:age, Shoddy.then_if(params["age"], &String.to_integer/1))
|> Shoddy.Maps.put_if(:email, Shoddy.then_if(params["email"], &String.downcase/1))
#=> %{name: "Ada", age: 36}
```

## Put an entry that depends on a condition

Sometimes the condition is not the value itself. Use `Shoddy.then_if/3`
with a predicate of arity 0. A predicate is a function that returns a
truthy value or a falsy value.

```elixir
admin? = true

%{name: "Ada"}
|> Shoddy.then_if(fn -> admin? end, &Map.put(&1, :role, :admin))
#=> %{name: "Ada", role: :admin}
```

If the predicate returns `nil` or `false`, the map stays with no change.

## Keep the value false

`Shoddy.Maps.put_if/3` ignores `false`. For a boolean field, `false` is
often a value that you must keep. Use `Shoddy.then_if/3` with a predicate
that examines the type:

```elixir
subscribed = false

%{name: "Ada"}
|> Shoddy.then_if(fn -> is_boolean(subscribed) end, &Map.put(&1, :subscribed, subscribed))
#=> %{name: "Ada", subscribed: false}
```
