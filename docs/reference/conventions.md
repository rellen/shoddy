# The conventions of the functions

This page gives the rules that apply to each function of Shoddy. The page of
each module gives the full description of each function.

## The modules

| Module | Contents |
| --- | --- |
| `Shoddy` | Functions that operate on any value: `then_if/2`, `then_if/3`, `id/1` and `coalesce/2`. |
| `Shoddy.Maps` | Functions that operate on maps: `put_if/3`. |
| `Shoddy.MapSets` | Functions that operate on map sets: `toggle/2` and `toggle_all/2`. |
| `Shoddy.Result` | Functions that operate on an ok tuple and on an error tuple. |
| `Shoddy.Tagging` | Functions that put a value into a tagged tuple. |
| `Shoddy.Hourglass` | Functions that change the precision of a time value: `extend/2`. |

The names `Maps` and `MapSets` are in the plural. Thus an alias of one of
these modules does not hide the standard module `Map` or `MapSet`.

## The order of the arguments

The first argument is the value that the function operates on. Thus each
function can be a step of a pipeline.

| Module | First argument |
| --- | --- |
| `Shoddy` | The value. For `coalesce/2`, the list of values. |
| `Shoddy.Maps` | The map. |
| `Shoddy.MapSets` | The map set. |
| `Shoddy.Result` | The result. For `from_nil/2`, the value. |
| `Shoddy.Tagging` | The value that goes into the tuple. The tag is the last argument of `tag/2` and `tag/3`. |
| `Shoddy.Hourglass` | The time value. |

## Truthy and falsy values

A truthy value is a value that is not `nil` and not `false`. A falsy value is
`nil` or `false`. Zero, an empty string and an empty collection are truthy.

These functions examine whether a value is truthy:

| Function | The value that it examines |
| --- | --- |
| `Shoddy.then_if/2` | The first argument. |
| `Shoddy.then_if/3` | The return value of the predicate. |
| `Shoddy.Maps.put_if/3` | The value to put into the map. |

`Shoddy.coalesce/2` does not examine whether a value is truthy. It rejects
only the values in its option `:reject`. The default is `[nil]`.

## Results

`Shoddy.Result` accepts four forms of a result:

| Form | Kind |
| --- | --- |
| `{:ok, value}` | An ok result with a value. |
| `:ok` | An ok result with no value. |
| `{:error, reason}` | An error result with a reason. |
| `:error` | An error result with no reason. |

A function that returns the value of an ok result returns `nil` for a bare
`:ok`.

## Equality

These functions compare two values with the strict equality operator
`===/2`. Thus the integer `1` and the float `1.0` are two different values.

- `Shoddy.coalesce/2`, for the values in its option `:reject`.
- `Shoddy.MapSets.toggle/2` and `Shoddy.MapSets.toggle_all/2`, for the
  elements of the map set.

## Errors

| Exception | Cause |
| --- | --- |
| `FunctionClauseError` | An argument of the wrong type. For example, a list as the first argument of `Shoddy.Maps.put_if/3`, or a function of the wrong arity. |
| `FunctionClauseError` | An input to `Shoddy.Result` that is not a result. `ok?/1`, `error?/1`, `flatten/1` and `from_nil/2` do not raise this error. |
| `FunctionClauseError` | The precision `:second` for `Shoddy.Hourglass.extend/2`. |
| `ArgumentError` | An unknown option, or an option value of the wrong type, for `Shoddy.coalesce/2`. |
| `ArgumentError` | An error result for `Shoddy.Result.unwrap!/1`. |

## Names

- A name that ends in `?` is the name of a function that returns a boolean.
  It never raises an exception for an input of the wrong type.
- A name that ends in `!` is the name of a function that raises an exception
  for an error result.
- A name that starts with `is_` is the name of a guard. Require or import the
  module before you use it.
