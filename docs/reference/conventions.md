# The conventions of the functions

This page gives the rules that apply to all the functions of Shoddy. The page
of each module gives the full description of each function.

## The modules

| Module | Functions |
| --- | --- |
| `Shoddy` | `Shoddy.then_if/2`, `Shoddy.then_if/3`, `Shoddy.then_present/3`, `Shoddy.id/1`, `Shoddy.coalesce/2` |
| `Shoddy.Maps` | `Shoddy.Maps.put_if/3`, `Shoddy.Maps.put_present/3`, `Shoddy.Maps.get_present/3`, `Shoddy.Maps.take_as/2`, `Shoddy.Maps.deep_merge/2`, `Shoddy.Maps.map_values/2`, `Shoddy.Maps.map_keys/2`, `Shoddy.Maps.put_path/3`, `Shoddy.Maps.fetch_keys/2`, `Shoddy.Maps.compact/1`, `Shoddy.Maps.increment/3`, `Shoddy.Maps.rename_key/3`, `Shoddy.Maps.stringify_keys/1`, `Shoddy.Maps.diff/2`, `Shoddy.Maps.invert/1` |
| `Shoddy.Keywords` | `Shoddy.Keywords.put_if/3`, `Shoddy.Keywords.put_present/3`, `Shoddy.Keywords.get_present/3`, `Shoddy.Keywords.compact/1` |
| `Shoddy.MapSets` | `Shoddy.MapSets.toggle/2`, `Shoddy.MapSets.toggle_all/2` |
| `Shoddy.Lists` | `Shoddy.Lists.duplicates/1`, `Shoddy.Lists.duplicates_by/2`, `Shoddy.Lists.has_duplicates?/1`, `Shoddy.Lists.index_by/2`, `Shoddy.Lists.single/1`, `Shoddy.Lists.group_by_in_order/2`, `Shoddy.Lists.upsert_by/4`, `Shoddy.Lists.sort_by_keys/2`, `Shoddy.Lists.toggle/2`, `Shoddy.Lists.move/3`, `Shoddy.Lists.sorted?/2`, `Shoddy.Lists.cycle_next/2`, `Shoddy.Lists.all_same_by?/2`, `Shoddy.Lists.join_by/4` |
| `Shoddy.Strings` | The guard `Shoddy.Strings.is_non_empty_string/1`, `Shoddy.Strings.presence/1`, `Shoddy.Strings.blank?/1`, `Shoddy.Strings.truncate/3`, `Shoddy.Strings.truncate_bytes/2`, `Shoddy.Strings.split_trim/2`, `Shoddy.Strings.mask/2`, `Shoddy.Strings.ensure_prefix/2`, `Shoddy.Strings.ensure_suffix/2` |
| `Shoddy.Parse` | `Shoddy.Parse.integer/2`, `Shoddy.Parse.float/2`, `Shoddy.Parse.boolean/2`, `Shoddy.Parse.one_of/2` |
| `Shoddy.Env` | `Shoddy.Env.integer/2`, `Shoddy.Env.boolean/2`, `Shoddy.Env.list/2` |
| `Shoddy.Numbers` | `Shoddy.Numbers.ceil_div/2`, `Shoddy.Numbers.clamp/3`, `Shoddy.Numbers.mean/1` |
| `Shoddy.Result` | Guards, predicates and transformations for an ok tuple and an error tuple |
| `Shoddy.Tagging` | A function for each usual tag, and `Shoddy.Tagging.tag/2` and `Shoddy.Tagging.tag/3` for the other tags |
| `Shoddy.DateTimes` | `Shoddy.DateTimes.extend_precision/2`, `Shoddy.DateTimes.floor/2`, `Shoddy.DateTimes.ceil/2`, `Shoddy.DateTimes.next_start/2`, `Shoddy.DateTimes.between?/3`, `Shoddy.DateTimes.overlap?/2`, `Shoddy.DateTimes.stream/3`, `Shoddy.DateTimes.round/2` |

The names `Maps`, `Keywords`, `MapSets`, `Lists`, `Strings` and `DateTimes`
are in the plural. Thus an alias of one of these modules does not hide the
standard module `Map`, `Keyword`, `MapSet`, `List`, `String` or `DateTime`.

## The order of the arguments

The first argument is the value that the function operates on. Thus each
function can be a step of a pipeline.

| Module | The first argument |
| --- | --- |
| `Shoddy` | The value. For `Shoddy.coalesce/2`, the list of values. |
| `Shoddy.Maps` | The map. For `Shoddy.Maps.deep_merge/2`, the map with the lower priority. For `Shoddy.Maps.diff/2`, the old map. |
| `Shoddy.Keywords` | The keyword list. |
| `Shoddy.MapSets` | The map set. |
| `Shoddy.Lists` | The list. |
| `Shoddy.Strings` | The value. |
| `Shoddy.Parse` | The text. |
| `Shoddy.Env` | The name of the environment variable. |
| `Shoddy.Numbers` | The number. For `Shoddy.Numbers.ceil_div/2`, the dividend. |
| `Shoddy.Result` | The result. For `Shoddy.Result.from_nil/2` and `Shoddy.Result.ensure/3`, the value. For `Shoddy.Result.collect/2`, the list or stream of results. For `Shoddy.Result.reduce_ok/3`, the enumerable. For `Shoddy.Result.collect_map/1`, the map of results. For `Shoddy.Result.attempt/2`, the function to call. |
| `Shoddy.Tagging` | The value that goes into the tuple. |
| `Shoddy.DateTimes` | The time value. For `Shoddy.DateTimes.between?/3`, the date or the time value to examine. For `Shoddy.DateTimes.overlap?/2`, the first period. |

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
| `Shoddy.Maps.map_values/2` | The function to apply to each value. | 1 |
| `Shoddy.Maps.map_keys/2` | The function to apply to each key. | 1 |
| `Shoddy.Lists.duplicates_by/2` | The function that returns the key of an element. | 1 |
| `Shoddy.Lists.index_by/2` | The function that returns the key of an element. | 1 |
| `Shoddy.Lists.group_by_in_order/2` | The function that returns the key of an element. | 1 |
| `Shoddy.Lists.upsert_by/4` | The function that returns the key of an element. | 1 |
| `Shoddy.Lists.sort_by_keys/2` | Each function in the list of keys. It returns the value to compare. | 1 |
| `Shoddy.Lists.sorted?/2` | A sorter function. It returns `true` if its first argument can come before its second argument. | 2 |
| `Shoddy.Lists.all_same_by?/2` | The function that returns the key of an element. | 1 |
| `Shoddy.Lists.join_by/4` | The two functions that return the key of an element of each list. | 1 |
| `Shoddy.coalesce/2` | A value in the list. The function calls it, and it examines the result. | 0 |
| `Shoddy.Result.collect/2` | The value of the option `:on_error`. The function calls it for each error that it examines. | 1 |
| `Shoddy.Result.recover/2` | The function to call with an error. | 1 |
| `Shoddy.Result.ensure/3` | The predicate. | 0 or 1 |
| `Shoddy.Result.reduce_ok/3` | The function to call with each element and the accumulator. It must return a result. | 2 |
| `Shoddy.Result.attempt/2` | The function to call. | 0 |
| `Shoddy.Result.unwrap_lazy/2` | The function that returns the default for an error. | 0 |

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

A bare `:ok` has the value `nil`, and a bare `:error` has the reason `nil`:

- `Shoddy.Result.unwrap/2`, `Shoddy.Result.unwrap_lazy/2` and
  `Shoddy.Result.unwrap!/1` return `nil` for a bare `:ok`.
- `Shoddy.Result.collect/2` puts `nil` into its list for a bare `:ok`.
- `Shoddy.Result.reduce_ok/3` uses `nil` as the new accumulator for a bare
  `:ok`.
- `Shoddy.Result.collect_map/1` gives the value `nil` for a bare `:ok`, and
  the reason `nil` for a bare `:error`.

`Shoddy.Result.recover/2` and the function of the option `:on_error` of
`Shoddy.Result.collect/2` receive the error as it is: `{:error, reason}` or a
bare `:error`.

`Shoddy.Lists.single/1`, `Shoddy.Maps.fetch_keys/2` and the functions of
`Shoddy.Parse` also return a result: `{:ok, value}` or `{:error, reason}`.
Thus the functions of `Shoddy.Result` accept their return values.

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
- `Shoddy.Lists.group_by_in_order/2` and `Shoddy.Lists.upsert_by/4`, for the
  keys of the elements.
- `Shoddy.Lists.toggle/2` and `Shoddy.Lists.cycle_next/2`, for the elements.
- `Shoddy.Lists.all_same_by?/2` and `Shoddy.Lists.join_by/4`, for the keys.
- `Shoddy.Maps.map_keys/2`, for the new keys.
- `Shoddy.Maps.fetch_keys/2`, for the keys to take.
- `Shoddy.Maps.diff/2`, for the values.
- `Shoddy.Maps.rename_key/3` and `Shoddy.Maps.invert/1`, for the keys.

## Errors

| Exception | Cause |
| --- | --- |
| `FunctionClauseError` | An argument of the wrong type, such as a list as the first argument of `Shoddy.Maps.put_if/3`. |
| `FunctionClauseError` | A function of the wrong arity. |
| `FunctionClauseError` | A struct as the argument `mapping` of `Shoddy.Maps.take_as/2`. |
| `FunctionClauseError` | A struct as an argument of `Shoddy.Maps.deep_merge/2`. |
| `FunctionClauseError` | A struct as an argument of `Shoddy.Maps.map_values/2`, `Shoddy.Maps.map_keys/2`, `Shoddy.Maps.compact/1`, `Shoddy.Maps.increment/3`, `Shoddy.Maps.rename_key/3`, `Shoddy.Maps.stringify_keys/1`, `Shoddy.Maps.diff/2` or `Shoddy.Maps.invert/1`. |
| `FunctionClauseError` | An empty path for `Shoddy.Maps.put_path/3`. |
| `FunctionClauseError` | An empty list of keys for `Shoddy.Lists.sort_by_keys/2`. |
| `FunctionClauseError` | An empty list for `Shoddy.Lists.cycle_next/2`, or a negative index for `Shoddy.Lists.move/3`. |
| `FunctionClauseError` | A value that is not `nil` or a string, for `Shoddy.Strings.blank?/1`. |
| `FunctionClauseError` | An empty separator for `Shoddy.Strings.split_trim/2`. |
| `FunctionClauseError` | A struct, or a value that is not a result, for `Shoddy.Result.collect_map/1`. |
| `FunctionClauseError` | A divisor of zero, or a value that is not an integer, for `Shoddy.Numbers.ceil_div/2`. |
| `FunctionClauseError` | A first argument of `Shoddy.Result.collect/2` that is not a list, a struct or a function of arity 2. A map is not accepted. |
| `FunctionClauseError` | An input to a function of `Shoddy.Result` that is not a result, or an element of the first argument of `Shoddy.Result.collect/2` that is not a result. `Shoddy.Result.ok?/1`, `Shoddy.Result.error?/1`, `Shoddy.Result.flatten/1`, `Shoddy.Result.from_nil/2` and `Shoddy.Result.ensure/3` accept each value. |
| `FunctionClauseError` | The precision `:second` for `Shoddy.DateTimes.extend_precision/2`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, or a `Time` with the unit `:day`, for `Shoddy.DateTimes.floor/2`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, or a `Time`, for `Shoddy.DateTimes.ceil/2`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, a `Time` or a `Date`, for `Shoddy.DateTimes.next_start/2`. |
| `FunctionClauseError` | A period that is not a tuple of two values, or four values that do not have the same type, for `Shoddy.DateTimes.overlap?/2`. |
| `FunctionClauseError` | Two values that are not both a `NaiveDateTime` or both a `DateTime` in UTC, for `Shoddy.DateTimes.stream/3`. |
| `FunctionClauseError` | A `DateTime` in a time zone other than UTC, a `Time` or a `Date`, for `Shoddy.DateTimes.round/2`. |
| `FunctionClauseError` | Three values that do not have the same type, or a value that is not a `Date`, a `Time`, a `NaiveDateTime` or a `DateTime`, for `Shoddy.DateTimes.between?/3`. |
| `ArgumentError` | An unknown option, or an option value of the wrong type, for `Shoddy.coalesce/2`. |
| `ArgumentError` | An unknown option for `Shoddy.then_present/3`. |
| `ArgumentError` | An unknown option, an omission that is not a string, or an omission that is longer than the maximum, for `Shoddy.Strings.truncate/3`. |
| `ArgumentError` | An unknown option, a limit that is not an integer or `nil`, or a `:min` that is higher than `:max`, for `Shoddy.Parse.integer/2`. |
| `ArgumentError` | An unknown option, a limit that is not a number or `nil`, or a `:min` that is higher than `:max`, for `Shoddy.Parse.float/2`. |
| `ArgumentError` | An unknown option, a value that is not a list of strings, or a text in the two lists, for `Shoddy.Parse.boolean/2`. |
| `ArgumentError` | An element of the allowed list that is not an atom, for `Shoddy.Parse.one_of/2`. |
| `ArgumentError` | An unknown option or an unknown option value for `Shoddy.Result.collect/2`, or a return value of the function of `:on_error` that is not in its list. |
| `ArgumentError` | An error result for `Shoddy.Result.unwrap!/1`. |
| `ArgumentError` | A return value of the function that is not a result, for `Shoddy.Result.reduce_ok/3`. |
| `ArgumentError` | An unknown option, or an absent, empty or wrong option `:rescue`, for `Shoddy.Result.attempt/2`. |
| `ArgumentError` | More than one key of the argument `mapping` with the same new name, or the new name `:__struct__`, for `Shoddy.Maps.take_as/2`. |
| `ArgumentError` | More than one key with the same new key, for `Shoddy.Maps.map_keys/2` and `Shoddy.Maps.stringify_keys/1`. |
| `ArgumentError` | A new key that is already in the map, for `Shoddy.Maps.rename_key/3`. |
| `ArgumentError` | More than one key with the same value, for `Shoddy.Maps.invert/1`. |
| `ArithmeticError` | A value that is not a number, for `Shoddy.Maps.increment/3` and `Shoddy.Numbers.mean/1`. |
| `ArgumentError` | A value on the path that is not a map and not `nil`, for `Shoddy.Maps.put_path/3`. |
| `ArgumentError` | More than one element with the same key, for `Shoddy.Lists.index_by/2`. |
| `ArgumentError` | An unknown option or a value of `:at` other than `:end` and `:start`, for `Shoddy.Lists.upsert_by/4`. |
| `ArgumentError` | A key in a wrong form, or a module that does not export `compare/2`, for `Shoddy.Lists.sort_by_keys/2`. |
| `ArgumentError` | A sorter in a wrong form, or a module that does not export `compare/2`, for `Shoddy.Lists.sorted?/2`. |
| `ArgumentError` | An index that is not in the list, for `Shoddy.Lists.move/3`. |
| `ArgumentError` | An element that is not in the list, for `Shoddy.Lists.cycle_next/2`. |
| `ArgumentError` | More than one element of the second list with the same key, for `Shoddy.Lists.join_by/4`. |
| `ArgumentError` | A minimum that is higher than the maximum, for `Shoddy.Numbers.clamp/3`. |
| `ArgumentError` | An unknown option, a count that is not a non-negative integer, or a `:char` that is not a string, for `Shoddy.Strings.mask/2`. |
| `ArgumentError` | A value of the variable that is not correct, or an unknown option, for `Shoddy.Env.integer/2`, `Shoddy.Env.boolean/2` and `Shoddy.Env.list/2`. |
| `System.EnvError` | An absent or empty variable without the option `:default`, for `Shoddy.Env.integer/2`, `Shoddy.Env.boolean/2` and `Shoddy.Env.list/2`. |
| `KeyError` | A key that is not a field of the struct, for `Shoddy.Maps.put_if/3`, `Shoddy.Maps.put_present/3` and `Shoddy.Maps.put_path/3` with a struct. `Shoddy.Maps.put_if/3` and `Shoddy.Maps.put_present/3` raise this error also if they do not put the value. |
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
