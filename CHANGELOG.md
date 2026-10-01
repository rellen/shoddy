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
