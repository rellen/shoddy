# Build a map from optional data

This guide shows how to build a map from data in which a field can be
absent, such as the parameters of a web form. The map gets an entry only for
a field that has a value. It does not get an entry such as `email: nil`.

Most functions in this guide examine whether a value is truthy. A truthy
value is a value that is not `nil` and not `false`. The last section shows a
function that ignores only `nil`.

To build a keyword list, such as the options of a function call, see
[Build a keyword list of options](build-a-keyword-list-of-options.md).

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

An empty string is truthy, so `Shoddy.Maps.put_if/3` puts it into the map. A
web form sends `""` for a field that the user did not fill in.
[Treat an empty string as no value](treat-an-empty-string-as-no-value.md)
shows how to ignore it.

## Take the fields of the parameters with new names

The parameters of a web form have string keys. Use `Shoddy.Maps.take_as/2`
to take the fields that you need and give them atom keys:

```elixir
params = %{"name" => "Ada", "email" => "ada@example.com", "admin" => "true"}

Shoddy.Maps.take_as(params, %{"name" => :name, "email" => :email})
#=> %{name: "Ada", email: "ada@example.com"}
```

The second argument gives the new name of each key. The result contains only
the keys of the second argument, so the field `"admin"` does not go into the
map. A key that is not in the parameters does not get an entry. A key with
the value `nil` gets an entry with `nil`. To remove it, use
`Shoddy.Maps.put_present/3` for that field instead.

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
`false` is a value that you must keep. Use `Shoddy.Maps.put_present/3`. It
ignores only `nil`:

```elixir
params = %{"name" => "Ada", "subscribed" => false, "email" => nil}

%{}
|> Shoddy.Maps.put_present(:name, params["name"])
|> Shoddy.Maps.put_present(:subscribed, params["subscribed"])
|> Shoddy.Maps.put_present(:email, params["email"])
#=> %{name: "Ada", subscribed: false}
```

## Change a value that can be false

`Shoddy.then_if/2` does not call the function for `false`. To change a value
that can be `false`, use `Shoddy.then_present/3`. It ignores only `nil`.
Then put the result with `Shoddy.Maps.put_present/3`:

```elixir
params = %{"name" => "Ada", "subscribed" => false}
status = &if(&1, do: :active, else: :inactive)

%{}
|> Shoddy.Maps.put_present(:name, params["name"])
|> Shoddy.Maps.put_present(:status, Shoddy.then_present(params["subscribed"], status))
#=> %{name: "Ada", status: :inactive}
```

[Transform an optional value](transform-an-optional-value.md) tells more
about `Shoddy.then_present/3`.
