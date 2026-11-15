# Transform an optional value

This guide shows how to apply a function to a value that can be `nil`. A
direct call of a function such as `String.trim/1` raises
`FunctionClauseError` for `nil`. Use `Shoddy.then_if/2` or
`Shoddy.then_present/3` instead. The guide also shows how to apply a
function only for a condition, with `Shoddy.then_when/3`.

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

## Transform a value only if a separate condition is true

Sometimes the condition is not the value itself, and the code already has
the condition as a value. Use `Shoddy.then_when/3`. It calls the function
only for a truthy condition:

```elixir
coupon_valid? = true

%{total: 100}
|> Shoddy.then_when(coupon_valid?, &Map.update!(&1, :total, fn total -> total - 10 end))
#=> %{total: 90}
```

For a falsy condition, the function returns the value with no change. The
call replaces `if coupon_valid?, do: change(order), else: order`.

If the condition needs a calculation on the value, use `Shoddy.then_if/3`
with a predicate:

```elixir
Shoddy.then_if(120, &(&1 > 100), &(&1 - 10))
#=> 110
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
