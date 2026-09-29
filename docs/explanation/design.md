# The design of Shoddy

This page tells why the functions of Shoddy behave as they do. For the rules
themselves, see [The conventions of the functions](../reference/conventions.md).

## The purpose

Elixir code repeats some small patterns frequently. Some examples are a
change to a value only if a condition is true, a map with optional entries,
and a list of sources for one value. Each pattern needs only a few lines of
code. But those lines often stop a pipeline, because the code must bind a
variable and write an `if` expression.

Shoddy gives each pattern a function with a name. The pipeline then
continues, and the name tells the reader the purpose of the step.

## No runtime dependencies

A small library must not add weight to each project that uses it. Shoddy
uses only the standard library of Elixir. Each dependency in `mix.exs` is for
development or for tests only.

## The value is the first argument

The pipe operator `|>` puts a value into the first argument of the next
function. The modules `Map`, `MapSet` and `Enum` of the standard library take
the value first for the same reason. Shoddy obeys the same rule. Thus each
function can be a step of a pipeline.

`Shoddy.Tagging.tag/2` also obeys this rule. The tag is the last argument,
although the tag is the first element of the tuple.

## The condition is truthiness

`Shoddy.then_if/2` and `Shoddy.Maps.put_if/3` examine whether a value is
truthy. A truthy value is a value that is not `nil` and not `false`. The macro
`if` and the operators `&&` and `||` use the same rule. Thus a reader who knows
`if` also knows the rule of these functions.

This rule has a cost. `Shoddy.Maps.put_if/3` never puts `false` into a map.
[Build a map from optional data](../how-to/build-a-map-from-optional-data.md)
shows how to keep `false`.

## Why coalesce rejects only nil

The expression `a || b` already returns the first truthy value.
`Shoddy.coalesce/2` has a different rule. By default, it rejects only `nil`.

This difference is important for a boolean option. For example, a user
sets an option to `false`, and the default of the option is `true`. The
expression `false || true` returns `true`, so the value that the user set
has no effect. The expression `Shoddy.coalesce([false, true])` returns
`false`, which is the correct value.

The option `:reject` adds other values, such as the empty string. The
function compares with `===/2`, so the result does not depend on a
conversion between an integer and a float.

The operator `||` does not evaluate its right side if the left side is
truthy. A list is different: Elixir evaluates each element of a list before
the function receives the list. A function of arity 0 in the list thus
delays its operation until `Shoddy.coalesce/2` examines it. The option
`call_functions?: false` is for a list in which a function is the value.

The function does not examine the value of the option `:default`, and it
does not call it. The default is the result for the case with no match, so a
second examination has no purpose.

## Results in four forms

Code in Elixir and in OTP returns a result in more than one form. OTP is the
set of standard libraries of the Erlang platform. For example, `File.write/2`
returns `:ok` or `{:error, reason}`. `Map.fetch/2` returns `{:ok, value}` or
`:error`. `Shoddy.Result` accepts each of these forms, so it can operate on
the return value of each of these functions.

Most functions of `Shoddy.Result` raise `FunctionClauseError` for an input
that is not a result. Such an input is a defect in the program. An error at
the place of the defect is easier to find than a wrong value at a later
place. The predicates `Shoddy.Result.ok?/1` and `Shoddy.Result.error?/1` are
different. They return `false` for each input that is not a result. Thus you
can use them with `Enum.filter/2` on a list of any values.

The names of the functions end in `_ok` or `_error`, as in
`Shoddy.Result.map_ok/2`. The name thus tells which form the function
changes. An import of the module also does not bring a general name, such as
`map`, into the scope.

## One element for each call of toggle

A map set can contain a list as an element. If `Shoddy.MapSets.toggle/2`
toggled each element of a list, then no call could toggle a list that is an
element. Thus `Shoddy.MapSets.toggle/2` always toggles one element, and
`Shoddy.MapSets.toggle_all/2` toggles each element of a list.

## Why Hourglass only extends

The precision of a time value is part of its struct, and `==` compares the
structs. Two values of the same point in time are thus unequal if their
precision is different.

Elixir can already make the precision higher. A call to `DateTime.add/4` with
an amount of 0 returns a value with the precision of the unit. But the name
`add` does not tell the reader the purpose of the call.
`Shoddy.Hourglass.extend/2` returns the same value, and its name tells the
purpose.

The function never lowers the precision, because a lower precision can
discard digits. The function `DateTime.truncate/2` and the functions of the
same name in `NaiveDateTime` and `Time` already do that operation, and
their name tells the reader about the loss.

The function refuses the precision `:second`. A precision of 0 digits is
the lowest precision, so a call with `:second` can never change a value.
Such a call is always a mistake.
