# Changelog

This file lists the changes to Shoddy in each release. `CLAUDE.md` gives the
rules for versions and releases.

## Unreleased

Shoddy has no release yet. The first release contains these modules:

- `Shoddy`
- `Shoddy.Maps`
- `Shoddy.MapSets`
- `Shoddy.Result`
- `Shoddy.Tagging`
- `Shoddy.DateTimes`

The first release also contains these changes:

- Add `Shoddy.Result.collect/1`. It converts a list of results into one
  result.
- Add `Shoddy.Maps.put_present/3`. It puts a value into a map if the value
  is not `nil`, so it keeps `false`.
- Add `Shoddy.DateTimes.floor/2`. It rounds a time value down to the start
  of a minute, an hour or a day.
