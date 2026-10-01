# Changelog

This file lists the changes to Shoddy in each release. `CLAUDE.md` gives the
rules for versions and releases.

## Unreleased

Shoddy has no release yet. The first release contains these modules:

- `Shoddy`
- `Shoddy.Maps`
- `Shoddy.Keywords`
- `Shoddy.MapSets`
- `Shoddy.Lists`
- `Shoddy.Strings`
- `Shoddy.Parse`
- `Shoddy.Result`
- `Shoddy.Tagging`
- `Shoddy.DateTimes`

The first release also contains these changes:

- Add `Shoddy.Result.collect/2`. It converts a list of results into one
  result. The option `:on_error` stops at the first error, skips each error,
  returns the reason of each error, or calls a function for each error.
- Add `Shoddy.Maps.put_present/3`. It puts a value into a map if the value
  is not `nil`, so it keeps `false`.
- Add `Shoddy.DateTimes.floor/2`. It rounds a time value down to the start
  of a minute, an hour or a day.
- Breaking: `Shoddy.Maps.put_if/3` and `Shoddy.Maps.put_present/3` raise
  `KeyError` for a struct and a key that is not a field of the struct. They
  raise this error also if they do not put the value.
- Add `Shoddy.Keywords` with `put_if/3` and `put_present/3`. They put a
  value into a keyword list with `Keyword.put/3`, which deletes each entry
  for the key.
- Add `Shoddy.Result.recover/2`. It calls a function with an error as it is,
  and the function returns a new result.
- Add `Shoddy.Result.ensure/3`. It returns an ok tuple if a predicate
  returns a truthy value, and an error tuple with a given reason otherwise.
- Add `Shoddy.Lists` with `duplicates/1` and `has_duplicates?/1`.
  `duplicates/1` returns each element that occurs more than one time in a
  list. `has_duplicates?/1` returns `true` if such an element exists.
- Add `Shoddy.Maps.take_as/2`. It takes keys from a map, and gives each key
  a new name from its argument `mapping`.
- `Shoddy.Result.collect/2` accepts a stream or another struct that implements
  `Enumerable`. With `on_error: :halt`, it reads no element after the first
  error, so a stream from `Stream.map/2` stops the operation at that error.
- Breaking: `Shoddy.MapSets.toggle_all/2` toggles each element of the list
  one time, also if the list contains the element more than one time. The
  result is equal to the result of `MapSet.symmetric_difference/2` with a map
  set of the list.
- Add `Shoddy.then_present/3`. It applies a function to a value that is not
  `nil`, and it returns the option `:default` for `nil`.
- Add `Shoddy.Lists.duplicates_by/2`. It returns a map from each key that
  more than one element has to the elements that have that key.
- Add `Shoddy.Lists.single/1`. It returns the only element of a list in an
  ok tuple. It returns `{:error, :empty}` for an empty list and
  `{:error, {:many, count}}` for more than one element.
- Add `Shoddy.Maps.deep_merge/2`. It merges two maps, and it merges each
  nested plain map of the same key. The right side replaces each other
  value, also a struct, a list and a keyword list.
- Add `Shoddy.DateTimes.ceil/2`. It rounds a time value up to the start of
  a minute, an hour or a day. A value at the start of a unit stays the same.
  It accepts a `NaiveDateTime` and a `DateTime` in UTC, but not a `Time`.
- Add `Shoddy.Strings` with the guard `is_non_empty_string/1` and the
  function `presence/1`. The guard accepts a binary that contains at least
  one byte. It rejects `nil`, `""` and each value that is not a binary.
  `presence/1` changes `""` to `nil`, and it returns each other value with
  no change.
- Add `Shoddy.Parse` with `integer/2` and `one_of/2`. `integer/2` converts
  text into an integer only if the text contains only the integer. The
  options `:min` and `:max` set a range. `one_of/2` converts text into an
  atom from a list, and it never makes a new atom.
- Add `Shoddy.Lists.index_by/2`. It returns a map from the key of each
  element to the element. It raises `ArgumentError` if more than one
  element has the same key.
- Add `Shoddy.Maps.get_present/3` and `Shoddy.Keywords.get_present/3`. They
  return the value of a key, or a default for an absent key and for `nil`.
  They return `false` with no change.
- Add `Shoddy.Result.reduce_ok/3`. It reduces an enumerable with a function
  that returns a result. It stops at the first error, also for a stream.
- Add `Shoddy.Strings.truncate/3`. It shortens a string to a maximum number
  of graphemes, and it puts the option `:omission` at the end. The omission
  is part of the maximum length.
- Add `Shoddy.DateTimes.between?/3`. It returns `true` if a date or a time
  is in a period that includes its first value and excludes its last value.
  It accepts a `DateTime` in each time zone.
- Add `Shoddy.Maps.map_values/2` and `Shoddy.Maps.map_keys/2`. They apply a
  function to each value or to each key. `map_keys/2` raises
  `ArgumentError` if two keys get the same new key.
- Add `Shoddy.Maps.put_path/3`. It puts a value into a nested map, and it
  makes each map on the path that is absent or `nil`.
- Add `Shoddy.Maps.fetch_keys/2`. It returns the given keys of a map, or
  `{:error, {:missing_keys, keys}}` with the keys that are absent.
