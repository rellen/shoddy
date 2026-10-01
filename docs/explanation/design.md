# The design of Shoddy

This page tells why the functions of Shoddy behave as they do. For the rules
themselves, see [The conventions of the functions](../reference/conventions.md).

## The purpose

Some small patterns occur frequently in Elixir code. Some examples are a
change to a value only if the value is present, a map with optional entries,
and a list of sources for one value. Each pattern needs only a few lines.
But those lines often stop a pipeline, because the code must bind a variable
and write an `if` expression:

```elixir
name = params["name"]
name = if name, do: String.trim(name), else: name
```

Shoddy gives each pattern a function with a name. The pipeline continues,
and the name tells the reader the purpose of the step:

```elixir
name = Shoddy.then_if(params["name"], &String.trim/1)
```

## No runtime dependencies

A project that uses Shoddy gets no other package. Shoddy uses only the
standard library of Elixir. Each dependency in `mix.exs` is for development
or for tests only.

## The value is the first argument

The pipe operator `|>` puts a value into the first argument of the next
function. The modules `Map`, `MapSet` and `Enum` take the value first for the
same reason. Shoddy obeys the same rule, so each function can be a step of a
pipeline.

`Shoddy.Tagging.tag/2` also obeys this rule. The tag is the last argument,
although the tag is the first element of the tuple.

## The condition is truthiness

`Shoddy.then_if/2` and `Shoddy.Maps.put_if/3` examine whether a value is
truthy. A truthy value is a value that is not `nil` and not `false`. The
macro `if` and the operators `&&` and `||` use the same rule. Thus a reader
who knows `if` also knows the rule of these functions.

This rule has a cost. `Shoddy.Maps.put_if/3` never puts `false` into a map.
Thus `Shoddy.Maps.put_present/3` has the rule of `Shoddy.coalesce/2`, and
it ignores only `nil`.
For the same reason, `Shoddy.then_present/3` ignores only `nil`, and it calls
the function for `false`. It also gives a default for `nil`. A default for
`Shoddy.then_if/2` would be ambiguous, because the function would return
the default for `false` too.
[Build a map from optional data](../how-to/build-a-map-from-optional-data.md#keep-a-field-that-can-be-false)
shows when to use each function.

## Why coalesce rejects only nil

The expression `a || b` already returns the first truthy value.
`Shoddy.coalesce/2` has a different rule. By default, it rejects only `nil`.

This difference is important for a boolean option. For example, a user sets
an option to `false`, and the default of the option is `true`:

```elixir
false || true
#=> true

Shoddy.coalesce([false, true])
#=> false
```

With `||`, the choice of the user has no effect. `Shoddy.coalesce/2` keeps
it.

The option `:reject` adds other values, such as the empty string. The
function compares with `===/2`. Thus `reject: [0]` does not reject `0.0`.

The operator `||` does not evaluate its right side if the left side is
truthy. A list is different, because Elixir evaluates each element of a list
before the function receives the list. Thus `Shoddy.coalesce/2` calls a
function of arity 0 in the list, and the function can delay an expensive
operation. The option `call_functions?: false` is for a list in which a
function is the value.

`Shoddy.coalesce/2` does not examine the value of the option `:default`, and
it does not call it. Thus the default can be any value, such as `nil` or a
function.

## Pipelines and with

`Shoddy.Result` gives a pipeline for a sequence of operations that can fail.
Each step receives the value of the step before it. An error goes to the end
with no change, unless a step recovers from it.

`Shoddy.Result.then_ok/2` continues the pipeline after an ok result.
`Shoddy.Result.recover/2` continues the pipeline after an error. It gives the
error to the next step, and an ok result goes to the end with no change.

The special form `with` does the same work as such a pipeline. Use `with` if
a step needs more than one earlier value, or if each error needs a different
treatment in the `else` clause. Use a pipeline of `Shoddy.Result` if each
step needs only the value of the step before it.

```elixir
with {:ok, text} <- Shoddy.Result.from_nil(params["age"], :no_age),
     {:ok, age} <- parse_age(text) do
  {:ok, age + 1}
end

params["age"]
|> Shoddy.Result.from_nil(:no_age)
|> Shoddy.Result.then_ok(&parse_age/1)
|> Shoddy.Result.map_ok(&(&1 + 1))
```

The two forms return the same result.

## Results in four forms

Elixir returns a result in more than one form. For example, `File.write/2`
returns `:ok` or `{:error, reason}`. `Map.fetch/2` returns `{:ok, value}` or
`:error`. `Shoddy.Result` accepts each of these forms, so it can operate on
the return value of each of these functions.

Most functions of `Shoddy.Result` raise `FunctionClauseError` for an input
that is not a result. Such an input is a defect in the program. An error at
the place of the defect is easier to find than a wrong value at a later
place.

The predicates `Shoddy.Result.ok?/1` and `Shoddy.Result.error?/1` are
different. They return `false` for each input that is not a result. Thus you
can use them with `Enum.filter/2` on a list of any values.

The names of the functions end in `_ok` or `_error`, as in
`Shoddy.Result.map_ok/2`. The name thus tells which form the function
changes. An import of the module also does not bring a general name, such as
`map`, into the scope.

## A stream for collect

Code often calls an operation that can fail for each element of a list, and
must stop at the first error. A function that takes the list and the
operation would do this work. But `Stream.map/2` already applies the
operation one element at a time, and only when the next step reads that
element.

Thus `Shoddy.Result.collect/2` accepts a stream, and Shoddy has no second
function for the same work. With `on_error: :halt`, the function reads no
element after the first error. The stream then does not call the operation
for a later element. The caller selects the behavior: `Enum.map/2` calls the
operation for each element, and `Stream.map/2` stops at the first error.

The function does not accept a map. A map is enumerable, but its elements
are key-value tuples. A map as the first argument is thus a mistake, and
`FunctionClauseError` tells the caller at once.

## Keyword lists in a separate module

`Access` reads maps and keyword lists in the same way, but a put is different.
`Keyword.put/3` deletes each entry for the key and puts the new entry at the
start of the list. One function for the two types would hide that
difference.

Thus `Shoddy.Keywords` is a separate module with the same function names as
`Shoddy.Maps`. The name of each module tells the type of its first argument,
and the documentation of each function tells its effect on that type. The
specifications stay exact: a map goes in and a map comes out, and a keyword
list goes in and a keyword list comes out.

## Structs in Shoddy.Maps

A struct is a map, so `Shoddy.Maps.put_if/3` and `Shoddy.Maps.put_present/3`
accept it. But `Map.put/3` can add a key that is not a field of the struct.
The result then is not a correct struct. For example, a wrong key such as
`:emial` makes a `%User{}` with an extra key, and no error occurs.

Thus the functions accept only a field of the struct as the key. They raise
`KeyError` for another key, as the update syntax `%{struct | key: value}`
does. They raise this error also if they do not put the value. A wrong key
then causes an error at the first call, and not only when the value is
present.

## New names in take_as

`Shoddy.Maps.take_as/2` converts the parameters of a web form, which have
string keys, into a map with atom keys. The user controls the keys of the
parameters. Thus the function never makes an atom from the input. Only the
values of the mapping become keys, and your code contains the mapping.

If two keys of the mapping have the same new name, the two values compete
for one key. The value in the result would then depend on the order in which
the function reads the mapping, and the contract of a map gives no order.
Thus the function raises `ArgumentError`. The message names each shared new
name with all of its keys, so you can correct the mapping in one step.

The new name `:__struct__` would make a result that looks like a struct but
has only some of its fields. Code that matches on the struct would then
accept an incorrect value. Thus the function raises `ArgumentError` for that
name, and the result is always a plain map.

The mapping must be a plain map. The guard rejects a struct with
`FunctionClauseError`, as for each other argument of the wrong type. Without
the guard, most structs would cause `Protocol.UndefinedError`, because they
do not implement `Enumerable`.

## One element for each call of toggle

A map set can contain a list as an element. If `Shoddy.MapSets.toggle/2`
toggled each element of a list, then no call could toggle a list that is an
element. Thus `Shoddy.MapSets.toggle/2` always toggles one element, and
`Shoddy.MapSets.toggle_all/2` toggles each element of a list.

## One toggle for each element of the list

`Shoddy.MapSets.toggle_all/2` toggles an element one time, also if the list
contains the element more than one time. A list of elements to toggle often
contains a duplicate by accident, for example after `++/2`. If the function
toggled the element one time for each occurrence, two occurrences would
cancel and the element would not change. The function would not tell you
about this.

With one toggle for each element, the result of
`Shoddy.MapSets.toggle_all/2` is equal to the result of
`MapSet.symmetric_difference/2` with a map set of the list. The function is
also fast for a short list and a large map set. On Elixir 1.19 and 1.20,
`MapSet.symmetric_difference/2` reads each element of the larger map set,
also for a list of a few elements.

To toggle an element one time for each occurrence, for example to apply a
list of events, call `Shoddy.MapSets.toggle/2` for each element with
`Enum.reduce/3`.

## How has_duplicates? finds a duplicate

`Shoddy.Lists.has_duplicates?/1` must be fast for two types of list. In a
list with a duplicate near the start, the function can stop at that
duplicate. In a list with no duplicates, the function must read each
element.

Two methods are available:

- A walk puts each element into a map, and stops at the first element that
  is already in the map.
- `:maps.from_keys/2` makes a map from all the elements in one call. The
  function then compares the size of the map with the length of the list.
  `:maps.from_keys/2` is a built-in function of the runtime, so it is
  approximately 4 times faster than the walk. But it cannot stop early.

Thus the function uses the two methods in sequence. It walks the first 1024
elements. If it finds no duplicate there, it calls `:maps.from_keys/2` for
the full list. This table shows the times for a list of 1 000 000 integers,
on OTP 28 (median of 7 runs):

| List | Walk | `:maps.from_keys/2` | `has_duplicates?/1` |
| --- | --- | --- | --- |
| No duplicates | 1144 ms | 283 ms | 282 ms |
| One duplicate at the end | 1105 ms | 303 ms | 257 ms |
| Many duplicates | 0.12 ms | 326 ms | 0.13 ms |
| One duplicate at index 1100 | 0.15 ms | 253 ms | 247 ms |

The last row shows the cost of this method. A duplicate just after the first
1024 elements gets the time of `:maps.from_keys/2`, although a walk would
stop soon after the first 1024 elements. In each other case,
`has_duplicates?/1` gets the time of the faster method.

`Shoddy.Lists.duplicates/1` must read each element in each case, so it does
not use this method.

## Why extend_precision never lowers the precision

The precision of a time value is part of its struct, and `==` compares the
structs. Thus two values of the same point in time are unequal if their
precision is different.

Elixir can already make the precision higher. A call to `DateTime.add/4` with
an amount of 0 returns a value with the precision of the unit. But the name
`add` does not tell the reader the purpose of the call.
`Shoddy.DateTimes.extend_precision/2` returns the same value, and its name
tells the purpose.

The function never lowers the precision, because a lower precision can
discard digits. `DateTime.truncate/2` and the functions of the same name in
`NaiveDateTime` and `Time` already do that operation, and their name tells
the reader about the loss.

The function refuses the precision `:second`. A precision of 0 digits is the
lowest precision, so a call with `:second` can never change a value. Such a
call is always a mistake.

## Why floor accepts only UTC

`Shoddy.DateTimes.floor/2` sets the fields below the unit to zero. For a
`NaiveDateTime`, a `Time` and a `DateTime` in UTC, the result is always a
correct value.

A time zone with daylight saving time is different. On the day of a change,
the clock skips some local times, or it shows some local times two times.
In some zones, the change occurs at midnight, so the start of that day does
not exist. The correct result then needs a time zone database, which tells
the offset of each local time. Shoddy has no runtime dependencies, so it
has no such database.

Thus the function raises `FunctionClauseError` for a `DateTime` in another
time zone, and it does not return a value that can be wrong. The caller
selects the rule. A conversion to UTC rounds the moment in UTC. A
conversion to a `NaiveDateTime` rounds the local wall time.
