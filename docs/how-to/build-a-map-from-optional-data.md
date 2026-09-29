# Build a map from optional data

This guide shows how to build a map from data in which a field can be
absent, such as the parameters of a web form. The map gets an entry only for
a field that has a value. It does not get an entry such as `email: nil`.

The functions in this guide examine whether a value is truthy. A truthy
value is a value that is not `nil` and not `false`.

## Put each field that has a value

Start with an empty map, and call `Shoddy.Maps.put_if/3` one time for each
field:

```elixir
params = %{"name" => "Ada", "email" => nil}

%{}
|> Shoddy.Maps.put_if(:name, params["name"])
|> Shoddy.Maps.put_if(:email, params["email"])
#=> %{name: "Ada"}
```

For `nil` or `false`, `Shoddy.Maps.put_if/3` returns the map with no change.
An entry that is already in the map stays.

## Change a value before you put it into the map

A function such as `String.trim/1` raises `FunctionClauseError` for `nil`.
Use `Shoddy.then_if/2` to call the function only for a truthy value:

```elixir
params = %{"name" => " Ada ", "email" => nil, "age" => "36"}

%{}
|> Shoddy.Maps.put_if(:name, Shoddy.then_if(params["name"], &String.trim/1))
|> Shoddy.Maps.put_if(:email, Shoddy.then_if(params["email"], &String.trim/1))
|> Shoddy.Maps.put_if(:age, Shoddy.then_if(params["age"], &String.to_integer/1))
#=> %{name: "Ada", age: 36}
```

## Put an entry that depends on a condition

Sometimes the condition is not the value itself. Use `Shoddy.then_if/3` with
a predicate of arity 0. A predicate is a function that returns a truthy value
or a falsy value. A falsy value is `nil` or `false`.

```elixir
admin? = true

%{name: "Ada"}
|> Shoddy.then_if(fn -> admin? end, &Map.put(&1, :role, :admin))
#=> %{name: "Ada", role: :admin}
```

If the predicate returns a falsy value, `Shoddy.then_if/3` returns the map
with no change.

## Keep a field that can be false

`Shoddy.Maps.put_if/3` never puts `false` into a map. For a boolean field,
`false` is a value that you must keep. Use `Shoddy.then_if/3` with a
predicate that examines the type:

```elixir
subscribed = false

%{name: "Ada"}
|> Shoddy.then_if(
  fn -> is_boolean(subscribed) end,
  &Map.put(&1, :subscribed, subscribed)
)
#=> %{name: "Ada", subscribed: false}
```

The map gets the entry for `true` and for `false`. It gets no entry for
`nil`.
