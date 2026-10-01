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
    {min, max} = limits!(opts)

    case Integer.parse(text) do
      {value, ""} -> check_range(value, min, max)
      _other -> {:error, :not_an_integer}
    end
  end

  defp limits!(opts) do
    opts = Keyword.validate!(opts, min: nil, max: nil)
    min = limit!(opts, :min)
    max = limit!(opts, :max)

    if min && max && min > max do
      raise ArgumentError, "the option :min (#{min}) is higher than the option :max (#{max})"
    end

    {min, max}
  end

  defp limit!(opts, name) do
    case Keyword.fetch!(opts, name) do
      limit when is_integer(limit) or is_nil(limit) ->
        limit

      other ->
        raise ArgumentError,
              "invalid value for #{inspect(name)} option: expected an integer or nil, got: #{inspect(other)}"
    end
  end

  defp check_range(value, min, _max) when is_integer(min) and value < min, do: {:error, :too_small}
  defp check_range(value, _min, max) when is_integer(max) and value > max, do: {:error, :too_large}
  defp check_range(value, _min, _max), do: {:ok, value}

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
