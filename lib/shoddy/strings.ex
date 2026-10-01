defmodule Shoddy.Strings do
  @moduledoc """
  Guards and functions that operate on strings, and add to the standard
  `String` module.

  The name of this module is `Strings`, in the plural. Thus the alias
  `Strings` does not hide the standard `String` module.

  A web form sends an empty string for a field that the user did not fill
  in. Thus `nil` and `""` often have the same meaning: no value. The guard
  `is_non_empty_string/1` rejects the two values in one check.
  """

  @doc """
  Tests if a value is a string that contains at least one byte.

  The guard rejects `nil`, `""`, and each value that is not a binary. Use it
  in a guard, or as an expression. Require or import the module first.

  A guard cannot examine the characters of a string. Thus the guard accepts
  a string of spaces, such as `" "`. To reject such a string, call
  `String.trim/1` before you test the value. The guard also cannot check
  that the binary is valid UTF-8, so it accepts each binary that is not
  empty.

  ## Examples

      iex> import Shoddy.Strings, only: [is_non_empty_string: 1]
      iex> is_non_empty_string("Ada")
      true

      iex> import Shoddy.Strings, only: [is_non_empty_string: 1]
      iex> is_non_empty_string("")
      false

      iex> import Shoddy.Strings, only: [is_non_empty_string: 1]
      iex> is_non_empty_string(nil)
      false

  The guard does not trim the string:

      iex> import Shoddy.Strings, only: [is_non_empty_string: 1]
      iex> is_non_empty_string(" ")
      true

  A charlist and an atom are not strings:

      iex> import Shoddy.Strings, only: [is_non_empty_string: 1]
      iex> {is_non_empty_string(~c"Ada"), is_non_empty_string(:ada)}
      {false, false}

  Use the guard in a function clause:

      iex> require Shoddy.Strings
      iex> greet = fn
      ...>   name when Shoddy.Strings.is_non_empty_string(name) -> "Hello, " <> name
      ...>   _name -> "Hello"
      ...> end
      iex> {greet.("Ada"), greet.(""), greet.(nil)}
      {"Hello, Ada", "Hello", "Hello"}
  """
  defguard is_non_empty_string(value) when is_binary(value) and value != ""
end
