# The conventions of the functions

This page gives the rules that apply to all the functions of Shoddy. The page
of each module gives the full description of each function.

## The modules

| Module | Functions |
| --- | --- |
| `Shoddy` | `Shoddy.then_if/2`, `Shoddy.then_if/3`, `Shoddy.then_present/3`, `Shoddy.id/1`, `Shoddy.coalesce/2` |
| `Shoddy.Maps` | `Shoddy.Maps.put_if/3`, `Shoddy.Maps.put_present/3`, `Shoddy.Maps.get_present/3`, `Shoddy.Maps.take_as/2`, `Shoddy.Maps.deep_merge/2` |
| `Shoddy.Keywords` | `Shoddy.Keywords.put_if/3`, `Shoddy.Keywords.put_present/3`, `Shoddy.Keywords.get_present/3` |
| `Shoddy.MapSets` | `Shoddy.MapSets.toggle/2`, `Shoddy.MapSets.toggle_all/2` |
| `Shoddy.Lists` | `Shoddy.Lists.duplicates/1`, `Shoddy.Lists.duplicates_by/2`, `Shoddy.Lists.has_duplicates?/1`, `Shoddy.Lists.index_by/2`, `Shoddy.Lists.single/1` |
| `Shoddy.Strings` | The guard `Shoddy.Strings.is_non_empty_string/1`, `Shoddy.Strings.presence/1` and `Shoddy.Strings.truncate/3` |
| `Shoddy.Parse` | `Shoddy.Parse.integer/2`, `Shoddy.Parse.one_of/2` |
| `Shoddy.Result` | Guards, predicates and transformations for an ok tuple and an error tuple |
| `Shoddy.Tagging` | A function for each usual tag, and `Shoddy.Tagging.tag/2` and `Shoddy.Tagging.tag/3` for the other tags |
| `Shoddy.DateTimes` | `Shoddy.DateTimes.extend_precision/2`, `Shoddy.DateTimes.floor/2`, `Shoddy.DateTimes.ceil/2`, `Shoddy.DateTimes.between?/3` |

The names `Maps`, `Keywords`, `MapSets`, `Lists`, `Strings` and `DateTimes`
are in the plural. Thus an alias of one of these modules does not hide the
standard module `Map`, `Keyword`, `MapSet`, `List`, `String` or `DateTime`.

## The order of the arguments

The first argument is the value that the function operates on. Thus each
function can be a step of a pipeline.

| Module | The first argument |
| --- | --- |
| `Shoddy` | The value. For `Shoddy.coalesce/2`, the list of values. |
| `Shoddy.Maps` | The map. For `Shoddy.Maps.deep_merge/2`, the map with the lower priority. |
| `Shoddy.Keywords` | The keyword list. |
| `Shoddy.MapSets` | The map set. |
| `Shoddy.Lists` | The list. |
| `Shoddy.Strings` | The value. |
| `Shoddy.Parse` | The text. |
| `Shoddy.Result` | The result. For `Shoddy.Result.from_nil/2` and `Shoddy.Result.ensure/3`, the value. For `Shoddy.Result.collect/2`, the list or stream of results. For `Shoddy.Result.reduce_ok/3`, the enumerable. |
| `Shoddy.Tagging` | The value that goes into the tuple. |
| `Shoddy.DateTimes` | The time value. For `Shoddy.DateTimes.between?/3`, the date or the time value to examine. |

In `Shoddy.Tagging.tag/2` and `Shoddy.Tagging.tag/3`, the tag is the last
argument.

## Truthy and falsy values

A truthy value is a value that is not `nil` and not `false`. A falsy value is
`nil` or `false`. Zero, an empty string and an empty collection are truthy.
To reject `nil` and an empty string together, use the guard
`Shoddy.Strings.is_non_empty_string/1`. To change an empty string to `nil`,
use `Shoddy.Strings.presence/1`.

| Function | The value that must be truthy |
| --- | --- |
| `Shoddy.then_if/2` | The first argument. |
| `Shoddy.then_if/3` | The return value of the predicate. |
| `Shoddy.Maps.put_if/3` | The value to put into the map. |
| `Shoddy.Keywords.put_if/3` | The value to put into the keyword list. |
| `Shoddy.Result.ensure/3` | The return value of the predicate. |

These functions do not use this rule:

- `Shoddy.Maps.put_present/3` ignores only `nil`.
- `Shoddy.Keywords.put_present/3` ignores only `nil`.
- `Shoddy.Maps.get_present/3` and `Shoddy.Keywords.get_present/3` return the
  default only for an absent key and for `nil`. They return `false`.
- `Shoddy.then_present/3` ignores only `nil`. It calls the function for
  `false`.
- `Shoddy.coalesce/2` rejects the values in its option `:reject`. The
  default of that option is `[nil]`.

## Functions as arguments

| Function | Argument | Arity |
| --- | --- | --- |
| `Shoddy.then_if/2` | The function to apply. | 1 |
| `Shoddy.then_if/3` | The predicate. | 0 or 1 |
| `Shoddy.then_if/3` | The function to apply. | 1 |
| `Shoddy.then_present/3` | The function to apply. | 1 |
| `Shoddy.Lists.duplicates_by/2` | The function that returns the key of an element. | 1 |
| `Shoddy.Lists.index_by/2` | The function that returns the key of an element. | 1 |
| `Shoddy.coalesce/2` | A value in the list. The function calls it, and it examines the result. | 0 |
| `Shoddy.Result.collect/2` | The value of the option `:on_error`. The function calls it for each error that it examines. | 1 |
| `Shoddy.Result.recover/2` | The function to call with an error. | 1 |
| `Shoddy.Result.ensure/3` | The predicate. | 0 or 1 |
| `Shoddy.Result.reduce_ok/3` | The function to call with each element and the accumulator. It must return a result. | 2 |

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
return `nil`, `Shoddy.Result.collect/2` puts `nil` into its list, and
`Shoddy.Result.reduce_ok/3` uses `nil` as the new accumulator.

`Shoddy.Result.recover/2` and the function of the option `:on_error` of
`Shoddy.Result.collect/2` receive the error as it is: `{:error, reason}` or a
bare `:error`.

`Shoddy.Lists.single/1` and the functions of `Shoddy.Parse` also return a
result: `{:ok, value}` or `{:error, reason}`. Thus the functions of
`Shoddy.Result` accept their return values.

## Equality

These functions compare two values with the strict equality operator
`===/2`. Thus the integer `1` and the float `1.0` are two different values.

- `Shoddy.coalesce/2`, for the values in its option `:reject`.
- `Shoddy.MapSets.toggle/2` and `Shoddy.MapSets.toggle_all/2`, for the
  elements of the map set.
- `Shoddy.Lists.duplicates/1` and `Shoddy.Lists.has_duplicates?/1`, for the
  elements of the list.
- `Shoddy.Lists.duplicates_by/2`, for the keys of the elements.
- `Shoddy.Lists.index_by/2`, for the keys of the elements.

## Errors

| Exception | Cause |
| --- | --- |
| `FunctionClauseError` | An argument of the wrong type, such as a list as the first argument of `Shoddy.Maps.put_if/3`. |
| `FunctionClauseError` | A function of the wrong arity. |
| `FunctionClauseError` | A struct as the argument `mapping` of `Shoddy.Maps.take_as/2`. |
| `FunctionClauseError` | A struct as an argument of `Shoddy.Maps.deep_merge/2`. |
| `FunctionClauseError` | A first argument of `Shoddy.Result.collect/2` that is not a list, a struct or a function of arity 2. A map is not accepted. |
| `FunctionClauseError` | An input to a function of `Shoddy.Result` that is not a result, or an element of the first argument of `Shoddy.Result.collect/2` that is not a result. `Shoddy.Result.ok?/1`, `Shoddy.Result.error?/1`, `Shoddy.Result.flatten/1`, `Shoddy.Result.from_nil/2` and `Shoddy.Result.ensure/3` accept each value. |
| `FunctionClauseError` | The precision `:second` for `Shoddy.DateTimes.extend_precision/2`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, or a `Time` with the unit `:day`, for `Shoddy.DateTimes.floor/2`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, or a `Time`, for `Shoddy.DateTimes.ceil/2`. |
| `FunctionClauseError` | Three values that do not have the same type, or a value that is not a `Date`, a `Time`, a `NaiveDateTime` or a `DateTime`, for `Shoddy.DateTimes.between?/3`. |
| `ArgumentError` | An unknown option, or an option value of the wrong type, for `Shoddy.coalesce/2`. |
| `ArgumentError` | An unknown option for `Shoddy.then_present/3`. |
| `ArgumentError` | An unknown option, an omission that is not a string, or an omission that is longer than the maximum, for `Shoddy.Strings.truncate/3`. |
| `ArgumentError` | An unknown option, a limit that is not an integer or `nil`, or a `:min` that is higher than `:max`, for `Shoddy.Parse.integer/2`. |
| `ArgumentError` | An element of the allowed list that is not an atom, for `Shoddy.Parse.one_of/2`. |
| `ArgumentError` | An unknown option or an unknown option value for `Shoddy.Result.collect/2`, or a return value of the function of `:on_error` that is not in its list. |
| `ArgumentError` | An error result for `Shoddy.Result.unwrap!/1`. |
| `ArgumentError` | A return value of the function that is not a result, for `Shoddy.Result.reduce_ok/3`. |
| `ArgumentError` | More than one key of the argument `mapping` with the same new name, or the new name `:__struct__`, for `Shoddy.Maps.take_as/2`. |
| `ArgumentError` | More than one element with the same key, for `Shoddy.Lists.index_by/2`. |
| `KeyError` | A key that is not a field of the struct, for `Shoddy.Maps.put_if/3` and `Shoddy.Maps.put_present/3` with a struct. The function raises this error also if it does not put the value. |
| `Protocol.UndefinedError` | A struct that does not implement `Enumerable`, as the first argument of `Shoddy.Result.collect/2`, or a first argument of `Shoddy.Result.reduce_ok/3` that is not enumerable. |

## Names

| Name | Rule |
| --- | --- |
| Ends in `?` | The function returns a boolean. It raises an exception only for an argument of the wrong type. |
| Ends in `!` | The function raises an exception for an error result. |
| Starts with `is_` | The name is a guard. Require or import the module before you use it. |
| Ends in `_if` | The function acts only if a condition is truthy. The condition is the value, or the return value of a predicate. See [Truthy and falsy values](#truthy-and-falsy-values). |
| Ends in `_present` | The function acts for each value that is not `nil`. It acts also for `false`. |
| Ends in `_by` | The function takes a function of arity 1 that returns the key of an element, as `Enum.uniq_by/2` does. |
