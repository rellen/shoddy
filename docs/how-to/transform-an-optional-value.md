# Transform an optional value

This guide shows how to apply a function to a value that can be `nil`. A
direct call of a function such as `String.trim/1` raises
`FunctionClauseError` for `nil`. Use `Shoddy.then_if/2` or
`Shoddy.then_present/3` instead.

## Transform a value only if it is present

`Shoddy.then_if/2` calls the function only for a truthy value. It returns
`nil` and `false` with no change:

```elixir
Shoddy.then_if(" Ada ", &String.trim/1)
#=> "Ada"

Shoddy.then_if(nil, &String.trim/1)
#=> nil
```

## Transform false as a value

`Shoddy.then_if/2` does not call the function for `false`. If `false` is a
value that the function must receive, use `Shoddy.then_present/3`. It
ignores only `nil`:

```elixir
Shoddy.then_if(false, &if(&1, do: "yes", else: "no"))
#=> false

Shoddy.then_present(false, &if(&1, do: "yes", else: "no"))
#=> "no"
```

## Give a result for nil

Give the option `:default` to `Shoddy.then_present/3`. The function returns
the default for `nil`, and it does not call the function:

```elixir
Shoddy.then_present(nil, &Enum.join(&1, " "), default: "all")
#=> "all"

Shoddy.then_present([2, 3], &Enum.join(&1, " "), default: "all")
#=> "2 3"
```

## Make a list of attributes from optional values

Give the default `[]` to get an empty list for `nil`. Then `++/2` joins the
lists, and a `nil` value adds no attribute:

```elixir
element = %{el: "intro", steps: nil}

Shoddy.then_present(element.el, &[{"data-el", &1}], default: []) ++
  Shoddy.then_present(element.steps, &[{"data-on", Enum.join(&1, " ")}], default: [])
#=> [{"data-el", "intro"}]
```

## Use a result of nil or false from the function

`Shoddy.then_if(value, fun) || default` also gives a default. But `||`
replaces each falsy result of `fun`, not only the result for `nil`.
`Shoddy.then_present/3` returns the result of `fun` with no change:

```elixir
Shoddy.then_if(42, fn _ -> false end) || :default
#=> :default

Shoddy.then_present(42, fn _ -> false end, default: :default)
#=> false
```
