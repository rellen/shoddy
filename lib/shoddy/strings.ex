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
  `String.trim/1` first. The predicate `blank?/1` also treats such a string
  as empty.

  The other functions change a string:

  - `truncate/3` shortens a string for display. It counts graphemes, which
    are the characters that a reader sees.
  - `truncate_bytes/2` shortens a string to a number of bytes, for storage.
  - `split_trim/2` splits a string into a list of values, and trims each
    value.
  - `mask/2` hides a secret, and keeps some graphemes visible.
  - `ensure_prefix/2` and `ensure_suffix/2` add a fixed text at an end of
    the string, if it is not there.
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

  The function checks the omission also for a string that it does not
  shorten. Thus a wrong omission raises an exception for each string, not
  only for a long one. For a `max` that can be 0, give `omission: ""`.

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

  @doc """
  Returns `true` for `nil`, an empty string and a string of whitespace only.

  Whitespace is a character such as a space, a tab or a newline. This
  function uses `String.trim/1`, so it also knows the Unicode whitespace,
  such as the no-break space.

  This function is not a guard, because a guard cannot trim a string. It
  accepts only `nil` and a string. For another value, it raises
  `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Strings.blank?(nil)
      true

      iex> Shoddy.Strings.blank?("")
      true

      iex> Shoddy.Strings.blank?(" \\t\\n")
      true

      iex> Shoddy.Strings.blank?(" Ada ")
      false
  """
  @spec blank?(String.t() | nil) :: boolean()
  def blank?(nil), do: true
  def blank?(value) when is_binary(value), do: String.trim(value) == ""

  @doc """
  Splits a string into a list of values, trims each value, and removes each
  empty value.

  The default separator is `","`. Give another string, or a list of
  strings, as the separator. This function raises `ArgumentError` for these
  separators:

  - An empty string or an empty list.
  - A list with a value that is not a string, or with an empty string.

  Use this function for a list in one field of a form or in one variable of
  the environment, such as `"red, green, ,blue"`.

  ## Examples

      iex> Shoddy.Strings.split_trim("red, green, ,blue")
      ["red", "green", "blue"]

      iex> Shoddy.Strings.split_trim("")
      []

      iex> Shoddy.Strings.split_trim("a; b\\nc", [";", "\\n"])
      ["a", "b", "c"]

  `String.split/2` keeps the spaces and the empty values:

      iex> String.split("red, green, ,blue", ",")
      ["red", " green", " ", "blue"]
  """
  @spec split_trim(String.t(), String.t() | [String.t(), ...]) :: [String.t()]
  def split_trim(string, separator \\ ",") when is_binary(string) and (is_binary(separator) or is_list(separator)) do
    string
    |> String.split(separator!(separator))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp separator!(separator) do
    separators = List.wrap(separator)

    if separators != [] and Enum.all?(separators, fn value -> is_non_empty_string(value) end) do
      separator
    else
      raise ArgumentError,
            "invalid separator: expected a non-empty string or a non-empty list of non-empty strings, " <>
              "got: #{inspect(separator)}"
    end
  end

  @doc """
  Shortens a string to a maximum number of bytes, and never cuts a grapheme.

  A database column or a protocol can limit the size of a value in bytes. A
  character in UTF-8 can use more than one byte, so a cut at a byte position
  can make a string that is not valid. This function returns the longest
  start of the string that contains only full graphemes and has `max_bytes`
  bytes or fewer.

  This function adds no omission. For display, use `truncate/3`, which
  counts graphemes.

  ## Examples

      iex> Shoddy.Strings.truncate_bytes("Hello", 3)
      "Hel"

      iex> Shoddy.Strings.truncate_bytes("Hello", 10)
      "Hello"

  The letter `ö` uses two bytes. The function does not cut it:

      iex> Shoddy.Strings.truncate_bytes("Möbius", 2)
      "M"

      iex> binary_part("Möbius", 0, 2) |> String.valid?()
      false
  """
  @spec truncate_bytes(String.t(), non_neg_integer()) :: String.t()
  def truncate_bytes(string, max_bytes) when is_binary(string) and is_integer(max_bytes) and max_bytes >= 0 do
    if byte_size(string) <= max_bytes do
      string
    else
      binary_part(string, 0, prefix_size(string, max_bytes, 0))
    end
  end

  defp prefix_size(rest, max_bytes, size) do
    case String.next_grapheme_size(rest) do
      {grapheme_size, rest} when size + grapheme_size <= max_bytes -> prefix_size(rest, max_bytes, size + grapheme_size)
      _end_or_too_large -> size
    end
  end

  @doc """
  Hides a string, such as a secret in a log, and keeps some graphemes visible.

  This function replaces each grapheme with the option `:char`, except the
  first `:keep_first` graphemes and the last `:keep_last` graphemes. The
  result has the same number of graphemes as the input, so it shows the
  length of the string.

  The function never shows more than half of the string. If `:keep_first`
  and `:keep_last` together are more than half of the length, it hides each
  grapheme. Thus a short secret stays hidden.

  ## Options

    * `:keep_last` - The number of graphemes to show at the end. The default
      is `4`.

    * `:keep_first` - The number of graphemes to show at the start. The
      default is `0`.

    * `:char` - The grapheme that replaces each hidden grapheme. The default
      is `"*"`. It must be a string of exactly one grapheme, so that the
      result has the length of the input.

  This function raises `ArgumentError` for these options:

  - An unknown option.
  - A count that is not a non-negative integer.
  - A `:char` that is not a string of exactly one grapheme.

  ## Examples

      iex> Shoddy.Strings.mask("4111111111111111")
      "************1111"

      iex> Shoddy.Strings.mask("sk_live_abcdef", keep_first: 3, keep_last: 2)
      "sk_*********ef"

  The function hides each grapheme of a short string:

      iex> Shoddy.Strings.mask("123456")
      "******"
  """
  @spec mask(String.t(), keyword()) :: String.t()
  def mask(string, opts \\ []) when is_binary(string) and is_list(opts) do
    opts = Keyword.validate!(opts, keep_first: 0, keep_last: 4, char: "*")
    keep_first = count!(opts, :keep_first)
    keep_last = count!(opts, :keep_last)
    char = char!(opts)
    graphemes = String.graphemes(string)
    count = length(graphemes)
    hidden = count - keep_first - keep_last

    if hidden < keep_first + keep_last do
      String.duplicate(char, count)
    else
      Enum.join(Enum.take(graphemes, keep_first)) <>
        String.duplicate(char, hidden) <> Enum.join(Enum.take(graphemes, -keep_last))
    end
  end

  defp count!(opts, name) do
    case Keyword.fetch!(opts, name) do
      count when is_integer(count) and count >= 0 ->
        count

      other ->
        raise ArgumentError,
              "invalid value for #{inspect(name)} option: expected a non-negative integer, got: #{inspect(other)}"
    end
  end

  defp char!(opts) do
    case Keyword.fetch!(opts, :char) do
      char when is_binary(char) -> if String.length(char) == 1, do: char, else: raise_char!(char)
      other -> raise_char!(other)
    end
  end

  defp raise_char!(value) do
    raise ArgumentError, "invalid value for :char option: expected a string of one grapheme, got: #{inspect(value)}"
  end

  @doc """
  Adds a prefix to a string, if the string does not start with it.

  Use this function for a value that must start with a fixed text. Examples
  are a scheme in a URL and a `#` before a color.

  ## Examples

      iex> Shoddy.Strings.ensure_prefix("example.com", "https://")
      "https://example.com"

      iex> Shoddy.Strings.ensure_prefix("https://example.com", "https://")
      "https://example.com"
  """
  @spec ensure_prefix(String.t(), String.t()) :: String.t()
  def ensure_prefix(string, prefix) when is_binary(string) and is_binary(prefix) do
    if String.starts_with?(string, prefix), do: string, else: prefix <> string
  end

  @doc """
  Adds a suffix to a string, if the string does not end with it.

  Use this function for a value that must end with a fixed text, such as a
  `/` at the end of a base URL.

  ## Examples

      iex> Shoddy.Strings.ensure_suffix("https://example.com/api", "/")
      "https://example.com/api/"

      iex> Shoddy.Strings.ensure_suffix("https://example.com/api/", "/")
      "https://example.com/api/"
  """
  @spec ensure_suffix(String.t(), String.t()) :: String.t()
  def ensure_suffix(string, suffix) when is_binary(string) and is_binary(suffix) do
    if String.ends_with?(string, suffix), do: string, else: string <> suffix
  end
end
