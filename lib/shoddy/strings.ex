defmodule Shoddy.Strings do
  @moduledoc """
  A guard and functions that operate on strings, and add to the standard
  `String` module.

  The name of this module is `Strings`, in the plural. Thus the alias
  `Strings` does not hide the standard `String` module.

  A web form sends an empty string for a field that the user did not fill
  in. Thus `nil` and `""` often have the same meaning: no value. This module
  has two tools for this case:

  - `is_non_empty_string/1` is a guard. It rejects `nil`, `""` and each value
    that is not a binary.
  - `presence/1` changes `""` to `nil`, and it returns each other value with
    no change. Then the functions that ignore `nil` also ignore `""`.

  Neither tool trims a string. Whitespace is a character such as a space, a
  tab or a newline. A string that contains only whitespace, such as `" "`, is
  not empty, so the two tools keep it. To treat such a string as empty, call
  `String.trim/1` first.

  `truncate/3` shortens a string for display. It counts graphemes, which are
  the characters that a reader sees.
  """

  @doc """
  Tests if a value is a string that contains at least one byte.

  The guard rejects `nil`, `""`, and each value that is not a binary. Use it
  in a guard, or as an expression. Require or import the module first.

  A guard can examine only a fixed number of bytes. It cannot examine each
  byte of a string of any length. Thus the guard cannot tell `" "`, which
  contains only whitespace, from `" a"`, which has content after the
  whitespace. The guard accepts the two strings. To reject a string that
  contains only whitespace, call `String.trim/1` before you test the value.

  UTF-8 is the encoding that Elixir uses for the characters of a string. A
  guard cannot call `String.valid?/1`, so it cannot check that a binary is
  valid UTF-8. Thus the guard accepts each binary that is not empty, as
  `is_binary/1` does.

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

  @doc """
  Returns `nil` for an empty string, and returns each other value with no
  change.

  Use this function before a function that ignores `nil`, such as
  `Shoddy.Maps.put_present/3`, `Shoddy.then_present/3` or `Shoddy.coalesce/2`.
  Then that function also ignores `""`.

  This function accepts each value. It does not change `false`, a number or
  a string that contains only whitespace. Thus it does not lose a value of
  another type.

  ## Examples

      iex> Shoddy.Strings.presence("")
      nil

      iex> Shoddy.Strings.presence("Ada")
      "Ada"

      iex> Shoddy.Strings.presence(nil)
      nil

  The function returns each value that is not `""` with no change:

      iex> Enum.map([" ", false, 0, []], &Shoddy.Strings.presence/1)
      [" ", false, 0, []]

  Use the function with `Shoddy.Maps.put_present/3`:

      iex> params = %{"name" => "Ada", "email" => "", "age" => 36}
      iex> %{}
      ...> |> Shoddy.Maps.put_present(:name, Shoddy.Strings.presence(params["name"]))
      ...> |> Shoddy.Maps.put_present(:email, Shoddy.Strings.presence(params["email"]))
      ...> |> Shoddy.Maps.put_present(:age, Shoddy.Strings.presence(params["age"]))
      %{name: "Ada", age: 36}
  """
  @spec presence(value) :: value | nil when value: any()
  def presence(""), do: nil
  def presence(value), do: value

  @doc """
  Shortens a string to a maximum number of graphemes.

  A grapheme is a character that a reader sees. It can contain more than one
  code point, such as a letter and an accent. This function counts
  graphemes, as `String.length/1` does. Thus it never cuts a character in
  half.

  If the string has `max` graphemes or fewer, this function returns it with
  no change. Otherwise, it returns the start of the string followed by the
  omission. The omission is part of the length, so the result never has more
  than `max` graphemes.

  ## Options

    * `:omission` - The string at the end of a shortened result. The default
      is `"…"`, which is one grapheme.

  This function raises `ArgumentError` for an unknown option, for an
  omission that is not a string, and for an omission that is longer than
  `max`.

  ## Examples

      iex> Shoddy.Strings.truncate("Hello, world", 8)
      "Hello, …"

      iex> Shoddy.Strings.truncate("Hello", 8)
      "Hello"

      iex> Shoddy.Strings.truncate("Hello, world", 8, omission: "...")
      "Hello..."

      iex> Shoddy.Strings.truncate("Hello, world", 5, omission: "")
      "Hello"

  The function counts graphemes, not bytes:

      iex> Shoddy.Strings.truncate("Größenänderung", 6)
      "Größe…"
  """
  @spec truncate(String.t(), non_neg_integer(), keyword()) :: String.t()
  def truncate(string, max, opts \\ []) when is_binary(string) and is_integer(max) and max >= 0 and is_list(opts) do
    omission = omission!(opts, max)

    if String.length(string) <= max do
      string
    else
      String.slice(string, 0, max - String.length(omission)) <> omission
    end
  end

  defp omission!(opts, max) do
    omission = opts |> Keyword.validate!(omission: "…") |> Keyword.fetch!(:omission)

    cond do
      not is_binary(omission) ->
        raise ArgumentError, "invalid value for :omission option: expected a string, got: #{inspect(omission)}"

      String.length(omission) > max ->
        raise ArgumentError, "the :omission option #{inspect(omission)} is longer than the maximum length #{max}"

      true ->
        omission
    end
  end
end
