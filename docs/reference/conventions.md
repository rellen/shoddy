# The conventions of the functions

This page gives the rules that apply to all the functions of Shoddy. The page
of each module gives the full description of each function.

## The modules

| Module | Functions |
| --- | --- |
| `Shoddy` | `Shoddy.then_if/2`, `Shoddy.then_if/3`, `Shoddy.id/1`, `Shoddy.coalesce/2` |
| `Shoddy.Maps` | `Shoddy.Maps.put_if/3`, `Shoddy.Maps.put_present/3` |
| `Shoddy.MapSets` | `Shoddy.MapSets.toggle/2`, `Shoddy.MapSets.toggle_all/2` |
| `Shoddy.Result` | Guards, predicates and transformations for an ok tuple and an error tuple |
| `Shoddy.Tagging` | A function for each usual tag, and `Shoddy.Tagging.tag/2` and `Shoddy.Tagging.tag/3` for the other tags |
| `Shoddy.DateTimes` | `Shoddy.DateTimes.extend_precision/2`, `Shoddy.DateTimes.floor/2` |

The names `Maps`, `MapSets` and `DateTimes` are in the plural. Thus an alias
of one of these modules does not hide the standard module `Map`, `MapSet` or
`DateTime`.

## The order of the arguments

The first argument is the value that the function operates on. Thus each
function can be a step of a pipeline.

| Module | The first argument |
| --- | --- |
| `Shoddy` | The value. For `Shoddy.coalesce/2`, the list of values. |
| `Shoddy.Maps` | The map. |
| `Shoddy.MapSets` | The map set. |
| `Shoddy.Result` | The result. For `Shoddy.Result.from_nil/2`, the value. |
| `Shoddy.Tagging` | The value that goes into the tuple. |
| `Shoddy.DateTimes` | The time value. |

In `Shoddy.Tagging.tag/2` and `Shoddy.Tagging.tag/3`, the tag is the last
argument.

## Truthy and falsy values

A truthy value is a value that is not `nil` and not `false`. A falsy value is
`nil` or `false`. Zero, an empty string and an empty collection are truthy.

| Function | The value that must be truthy |
| --- | --- |
| `Shoddy.then_if/2` | The first argument. |
| `Shoddy.then_if/3` | The return value of the predicate. |
| `Shoddy.Maps.put_if/3` | The value to put into the map. |

These functions do not use this rule:

- `Shoddy.Maps.put_present/3` ignores only `nil`.
- `Shoddy.coalesce/2` rejects the values in its option `:reject`. The
  default of that option is `[nil]`.

## Functions as arguments

| Function | Argument | Arity |
| --- | --- | --- |
| `Shoddy.then_if/2` | The function to apply. | 1 |
| `Shoddy.then_if/3` | The predicate. | 0 or 1 |
| `Shoddy.then_if/3` | The function to apply. | 1 |
| `Shoddy.coalesce/2` | A value in the list. The function calls it, and it examines the result. | 0 |

`Shoddy.coalesce/2` does not call a function of arity 0 if the option
`call_functions?` is `false`. It never calls a function of another arity.

## Results

`Shoddy.Result` accepts four forms of a result:

| Form | Kind |
| --- | --- |
| `{:ok, value}` | An ok result with a value. |
| `:ok` | An ok result with no value. |
| `{:error, reason}` | An error result with a reason. |
| `:error` | An error result with no reason. |

For a bare `:ok`, `Shoddy.Result.unwrap/2` and `Shoddy.Result.unwrap!/1`
return `nil`, and `Shoddy.Result.collect/1` puts `nil` into its list.

## Equality

These functions compare two values with the strict equality operator
`===/2`. Thus the integer `1` and the float `1.0` are two different values.

- `Shoddy.coalesce/2`, for the values in its option `:reject`.
- `Shoddy.MapSets.toggle/2` and `Shoddy.MapSets.toggle_all/2`, for the
  elements of the map set.

## Errors

| Exception | Cause |
| --- | --- |
| `FunctionClauseError` | An argument of the wrong type, such as a list as the first argument of `Shoddy.Maps.put_if/3`. |
| `FunctionClauseError` | A function of the wrong arity. |
| `FunctionClauseError` | An input to a function of `Shoddy.Result` that is not a result, or an element of the list of `Shoddy.Result.collect/1` that is not a result. `Shoddy.Result.ok?/1`, `Shoddy.Result.error?/1`, `Shoddy.Result.flatten/1` and `Shoddy.Result.from_nil/2` accept each value. |
| `FunctionClauseError` | The precision `:second` for `Shoddy.DateTimes.extend_precision/2`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, or a `Time` with the unit `:day`, for `Shoddy.DateTimes.floor/2`. |
| `ArgumentError` | An unknown option, or an option value of the wrong type, for `Shoddy.coalesce/2`. |
| `ArgumentError` | An error result for `Shoddy.Result.unwrap!/1`. |

## Names

| Name | Rule |
| --- | --- |
| Ends in `?` | The function returns a boolean. It never raises an exception. |
| Ends in `!` | The function raises an exception for an error result. |
| Starts with `is_` | The name is a guard. Require or import the module before you use it. |
