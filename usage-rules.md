# Usage rules for Shoddy

Shoddy is a library of small functions for tasks that occur frequently in
Elixir code. These rules tell an AI agent how to use the library correctly.
The documentation of each module gives the full description.

## General rules

- Use the standard library if it has a function for the task. Use Shoddy
  for a task that the standard library does not do in one call.
- The module names are in the plural: `Shoddy.Maps`, `Shoddy.Keywords`,
  `Shoddy.MapSets`, `Shoddy.Lists`, `Shoddy.Strings`, `Shoddy.DateTimes`.
  No module `Shoddy.Map` or `Shoddy.String` exists.
- The first argument is the value that the function operates on. Thus each
  function can be a step of a pipeline.
- A function raises `FunctionClauseError` for an argument of the wrong
  type, and `ArgumentError` for a wrong option. Do not rescue these errors.
  Correct the call.
- The functions compare with `===/2`. Thus `1` and `1.0` are two different
  keys.

## The suffix of a name

- `_if` tests a value that the function also uses. The value must be
  truthy, which means not `nil` and not `false`. Zero, `""` and `[]` are
  truthy.
- `_when` tests a condition that is a separate argument.
- `_present` tests that a value is not `nil`. Thus it keeps `false`.

Examples of these rules:

- `Shoddy.Maps.put_if/3` does not put `false`. For a field that can be
  `false`, use `Shoddy.Maps.put_present/3`.
- `Shoddy.then_if/3` takes a predicate, which is a function.
  `Shoddy.then_when/3` takes a condition that is a value. Each one raises
  `FunctionClauseError` for the other form.
- To treat `""` as no value, change it to `nil` first with
  `Shoddy.Strings.presence/1`.

## Results

- `Shoddy.Result` accepts `{:ok, value}`, `:ok`, `{:error, reason}` and
  `:error`. It does not accept a tuple of three elements. Give such a tuple
  to `Shoddy.Result.normalize/1` first.
- Use `Shoddy.Result.map_ok/2` for a function that returns a plain value.
  Use `Shoddy.Result.then_ok/2` for a function that returns a result.
- `Shoddy.Result.attempt/2` needs the option `:rescue` or the option
  `:catch`. It does not rescue each exception by default.
- The functions of `Shoddy.Parse` return `{:ok, value}` or
  `{:error, reason}`, and they examine the full text. Thus `"12px"` is an
  error. `Shoddy.Parse.integer!/2` and `Shoddy.Parse.float!/2` raise.
- The functions of `Shoddy.Env` raise an exception for an absent variable
  or a wrong value. Use them in `config/runtime.exs`, and give the option
  `:default` for an optional variable.

## Functions that an agent can use incorrectly

- `Shoddy.Tagging.reply/2` and `Shoddy.Tagging.stop/2` take the reply or
  the reason first. At the end of a pipeline of the state, use
  `Shoddy.Tagging.reply_with/2` and `Shoddy.Tagging.stop_with/2`.
- Import `Shoddy.Tagging` with the option `:only`. In a module that imports
  `Plug.Conn`, do not import `Shoddy.Tagging.halt/1`.
- `Shoddy.Maps.get_and_increment/3` returns the count after the addition,
  and not the count before it. The result is `{count, map}`.
- `Shoddy.Maps.get_or_put_lazy/3` also returns `{value, map}`. Keep the
  map, or the new entry is lost.
- `Shoddy.DateTimes.between?/3` excludes the last value of the period.
  `Shoddy.DateTimes.within?/3` includes it, and it accepts `nil` for a
  period with no end.
- `Shoddy.MapSets.toggle/2` is for an event that asks for a change. For an
  event that carries the new state, use `Shoddy.MapSets.put_or_delete/3`.
- `Shoddy.Lists.index_by/3` raises `ArgumentError` if two elements have the
  same key. The option `:on_duplicate` changes this.
- `Shoddy.Strings.truncate/3` counts graphemes, for text that a person
  reads. `Shoddy.Strings.truncate_bytes/2` counts bytes, and it is only for
  text. For binary data that is not text, use `binary_slice/3`.
- `Shoddy.Strings.upcase_first/1` keeps the rest of the string.
  `String.capitalize/1` changes the rest to lower case.

## Tests

- Use `Shoddy.Tests` only in an ExUnit test. A release does not contain
  ExUnit.
- `Shoddy.Tests.suspend/1`, `Shoddy.Tests.put_app_env/3` and
  `Shoddy.Tests.put_system_env/2` restore the old state at the end of the
  test. Call them from the test process or from a `setup` callback.
- Do not use `async: true` in a test module that calls
  `Shoddy.Tests.put_app_env/3` or `Shoddy.Tests.put_system_env/2`.
