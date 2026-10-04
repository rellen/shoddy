defmodule Shoddy.Parse do
  @moduledoc """
  Functions that convert text, such as user input, into a value.

  Each function returns a result: `{:ok, value}` for correct text, and
  `{:error, reason}` for other text. Thus the functions of `Shoddy.Result`
  can continue the pipeline.

  Each function examines the full text. It does not accept text that starts
  with a correct value and continues with other characters. It also does not
  trim the text. To accept spaces at the two ends, call `String.trim/1` first.

  The module contains these functions:

  - `integer/2` converts text into an integer. It can also check a range.
  - `float/2` converts text into a float. It can also check a range.
  - `boolean/2` converts text into `true` or `false`.
  - `one_of/2` converts text into one atom from a list that you give. It does
    not make a new atom.
  """

  @doc """
  Converts text into an integer.

  The text must contain only the integer. A sign `+` or `-` can come first.
  This function returns `{:error, :not_an_integer}` for other text. For
  example, `Integer.parse("12abc")` returns `{12, "abc"}`, but this function
  returns an error for the same text.

  ## Options

    * `:min` - The lowest integer to accept. For a lower integer, this
      function returns `{:error, :too_small}`. The default is `nil`, which
      sets no limit.

    * `:max` - The highest integer to accept. For a higher integer, this
      function returns `{:error, :too_large}`. The default is `nil`, which
      sets no limit.

  This function raises `ArgumentError` for these options:

  - An unknown option.
  - A limit that is not an integer or `nil`.
  - A `:min` that is higher than `:max`.

  ## Examples

      iex> Shoddy.Parse.integer("42")
      {:ok, 42}

      iex> Shoddy.Parse.integer("-7")
      {:ok, -7}

      iex> Shoddy.Parse.integer("12abc")
      {:error, :not_an_integer}

      iex> Shoddy.Parse.integer("")
      {:error, :not_an_integer}

  The function does not trim the text:

      iex> Shoddy.Parse.integer(" 42")
      {:error, :not_an_integer}

  The options `:min` and `:max` set a range:

      iex> Shoddy.Parse.integer("0", min: 1)
      {:error, :too_small}

      iex> Shoddy.Parse.integer("101", min: 1, max: 100)
      {:error, :too_large}

      iex> Shoddy.Parse.integer("100", min: 1, max: 100)
      {:ok, 100}

  Use the function in a pipeline of results:

      iex> %{"page" => "3"}
      ...> |> Map.get("page", "1")
      ...> |> Shoddy.Parse.integer(min: 1)
      ...> |> Shoddy.Result.unwrap(1)
      3
  """
  @spec integer(String.t(), keyword()) :: {:ok, integer()} | {:error, :not_an_integer | :too_small | :too_large}
  def integer(text, opts \\ []) when is_binary(text) and is_list(opts) do
    {min, max} = limits!(opts, :integer)

    case Integer.parse(text) do
      {value, ""} -> check_range(value, min, max)
      _other -> {:error, :not_an_integer}
    end
  end

  defp limits!(opts, kind) do
    opts = Keyword.validate!(opts, min: nil, max: nil)
    min = limit!(opts, :min, kind)
    max = limit!(opts, :max, kind)

    if min && max && min > max do
      raise ArgumentError, "the option :min (#{min}) is higher than the option :max (#{max})"
    end

    {min, max}
  end

  defp limit!(opts, name, kind) do
    case Keyword.fetch!(opts, name) do
      nil ->
        nil

      limit when kind == :integer and is_integer(limit) ->
        limit

      limit when kind == :number and is_number(limit) ->
        limit

      other ->
        raise ArgumentError,
              "invalid value for #{inspect(name)} option: expected #{describe(kind)} or nil, got: #{inspect(other)}"
    end
  end

  defp describe(:integer), do: "an integer"
  defp describe(:number), do: "a number"

  defp check_range(value, min, _max) when is_number(min) and value < min, do: {:error, :too_small}
  defp check_range(value, _min, max) when is_number(max) and value > max, do: {:error, :too_large}
  defp check_range(value, _min, _max), do: {:ok, value}

  @doc """
  Converts text into a float.

  The text must contain only the number. A sign, a fractional part and an
  exponent are accepted, as `Float.parse/1` accepts them. Text without a
  decimal point, such as `"3"`, gives a float too. This function returns
  `{:error, :not_a_float}` for other text.

  A float has a limited range. A number that is too large for a float, such
  as `"1e400"`, also gives `{:error, :not_a_float}`. A number that is too
  close to zero, such as `"1e-400"`, gives `0.0`, as `Float.parse/1` does.

  ## Options

    * `:min` - The lowest number to accept. For a lower number, this
      function returns `{:error, :too_small}`. The default is `nil`.

    * `:max` - The highest number to accept. For a higher number, this
      function returns `{:error, :too_large}`. The default is `nil`.

  The limits can be integers or floats. This function raises
  `ArgumentError` for these options:

  - An unknown option.
  - A limit that is not a number or `nil`.
  - A `:min` that is higher than `:max`.

  ## Examples

      iex> Shoddy.Parse.float("1.5")
      {:ok, 1.5}

      iex> Shoddy.Parse.float("3")
      {:ok, 3.0}

      iex> Shoddy.Parse.float("2.5e3")
      {:ok, 2500.0}

      iex> Shoddy.Parse.float("1.5 kg")
      {:error, :not_a_float}

      iex> Shoddy.Parse.float("0.5", min: 1)
      {:error, :too_small}
  """
  @spec float(String.t(), keyword()) :: {:ok, float()} | {:error, :not_a_float | :too_small | :too_large}
  def float(text, opts \\ []) when is_binary(text) and is_list(opts) do
    {min, max} = limits!(opts, :number)

    case Float.parse(text) do
      {value, ""} -> check_range(value, min, max)
      _other -> {:error, :not_a_float}
    end
  end

  @doc """
  Converts text into a boolean.

  By default, this function accepts only `"true"` and `"false"`. These are
  the values that a checkbox of Phoenix sends, and the values that JSON
  uses. The comparison is case-sensitive. For other text, this function
  returns `{:error, :not_a_boolean}`.

  ## Options

    * `:true_values` - The list of texts that give `true`. The default is
      `["true"]`.

    * `:false_values` - The list of texts that give `false`. The default is
      `["false"]`.

  This function raises `ArgumentError` for these options:

  - An unknown option.
  - A value that is not a list of strings.
  - A text that is in the two lists.

  ## Examples

      iex> Shoddy.Parse.boolean("true")
      {:ok, true}

      iex> Shoddy.Parse.boolean("false")
      {:ok, false}

      iex> Shoddy.Parse.boolean("yes")
      {:error, :not_a_boolean}

  Give the lists for other texts, such as the value of an environment
  variable:

      iex> Shoddy.Parse.boolean("1", true_values: ["1", "true"], false_values: ["0", "false"])
      {:ok, true}
  """
  @spec boolean(String.t(), keyword()) :: {:ok, boolean()} | {:error, :not_a_boolean}
  def boolean(text, opts \\ []) when is_binary(text) and is_list(opts) do
    opts = Keyword.validate!(opts, true_values: ["true"], false_values: ["false"])
    true_values = texts!(opts, :true_values)
    false_values = texts!(opts, :false_values)

    if common = Enum.find(true_values, &(&1 in false_values)) do
      raise ArgumentError, "the text #{inspect(common)} is in :true_values and in :false_values"
    end

    cond do
      text in true_values -> {:ok, true}
      text in false_values -> {:ok, false}
      true -> {:error, :not_a_boolean}
    end
  end

  defp texts!(opts, name) do
    case Keyword.fetch!(opts, name) do
      texts when is_list(texts) ->
        if Enum.all?(texts, &is_binary/1), do: texts, else: raise_texts!(name, texts)

      other ->
        raise_texts!(name, other)
    end
  end

  defp raise_texts!(name, value) do
    raise ArgumentError, "invalid value for #{inspect(name)} option: expected a list of strings, got: #{inspect(value)}"
  end

  @doc """
  Converts text into one atom from a list of allowed atoms.

  The text must be equal to the name of an atom in `allowed`, as
  `Atom.to_string/1` returns it. The comparison is case-sensitive. For other
  text, this function returns `{:error, :not_allowed}`.

  This function never makes a new atom. The runtime never removes an atom,
  and the number of atoms has a limit. Thus `String.to_atom/1` on user input
  lets a user fill the table of atoms. `String.to_existing_atom/1` also
  accepts the name of each atom that exists in the system, not only the
  atoms that the code expects.

  This function raises `ArgumentError` if an element of `allowed` is not an
  atom.

  ## Examples

      iex> Shoddy.Parse.one_of("desc", [:asc, :desc])
      {:ok, :desc}

      iex> Shoddy.Parse.one_of("sideways", [:asc, :desc])
      {:error, :not_allowed}

      iex> Shoddy.Parse.one_of("DESC", [:asc, :desc])
      {:error, :not_allowed}

  Use the function in a pipeline of results, with a default:

      iex> %{"sort" => "name"}
      ...> |> Map.get("sort", "")
      ...> |> Shoddy.Parse.one_of([:name, :email, :inserted_at])
      ...> |> Shoddy.Result.unwrap(:inserted_at)
      :name
  """
  @spec one_of(String.t(), [atom()]) :: {:ok, atom()} | {:error, :not_allowed}
  def one_of(text, allowed) when is_binary(text) and is_list(allowed) do
    if not Enum.all?(allowed, &is_atom/1) do
      raise ArgumentError, "each element of the allowed list must be an atom, got: #{inspect(allowed)}"
    end

    Enum.find_value(allowed, {:error, :not_allowed}, fn atom ->
      if Atom.to_string(atom) == text, do: {:ok, atom}
    end)
  end
end
