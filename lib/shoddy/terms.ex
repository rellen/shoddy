defmodule Shoddy.Terms do
  @moduledoc """
  Functions that describe any term.

  A term is any value of Elixir or Erlang.

  The module contains this function:

  - `shape/2` describes the form of a term, and it hides the data in the
    term. Use it to write a term into a log.
  """

  @most_errors 5

  @doc """
  Describes the form of a term, and hides the data in the term.

  Use this function for a line of a log, or for the message of an error. A
  log often goes to a service of another company, and a person can read it.
  `inspect/1` shows each value of a term. Thus a term can put a name, an
  address, a password or a token into the log. This function shows only
  these parts:

  - an atom, as `inspect/1` shows it. Code writes an atom, so an atom
    contains no data.
  - the kind of each other basic value, such as `binary` or `integer`.
  - the module of a struct, and the size of a map.
  - the parts of a tuple, each as a shape.
  - the module of an exception, and some of its fields. The option
    `:fields` gives the names of those fields.

  For a list that is not empty, the function returns `list`. A list of
  exceptions is different: the function shows the first #{@most_errors} exceptions,
  and the number of the others.

  The function shows a field of an exception only if the field contains an
  atom, a tuple, an exception or a list of exceptions. The function does not
  show `nil`, `true` and `false`. It does not show a field with another
  value, because such a field can contain data. For example, the message of
  an exception often contains the value that the code refused.

  ## Options

    * `:fields` - The list of the fields of an exception to show. The
      default is `[:reason]`.

    * `:depth` - The number of levels of tuples and exceptions that the
      function opens. At the last level, the function shows only the size of
      a tuple and the module of an exception. The default is 4.

  This function raises `ArgumentError` for an unknown option, for a
  `:fields` that is not a list of atoms, and for a `:depth` that is not a
  non-negative integer.

  ## Examples

      iex> Shoddy.Terms.shape({:error, %{name: "Ada"}, "a note"})
      "{:error, map(1), binary}"

      iex> Shoddy.Terms.shape([1, 2, 3])
      "list"

      iex> Shoddy.Terms.shape(%URI{host: "example.com"})
      "%URI{}"

  The function shows the module of an exception and the atom in its field
  `:reason`:

      iex> Shoddy.Terms.shape(%File.Error{reason: :enoent, path: "/home/ada/notes.txt"})
      "File.Error(reason: :enoent)"

  The message of an exception contains data, so the function does not show
  it:

      iex> Shoddy.Terms.shape(%ArgumentError{message: "invalid email: ada@example.com"})
      "ArgumentError"

  The option `:fields` selects other fields:

      iex> error = %KeyError{key: :name, term: %{"name" => "Ada"}}
      iex> Shoddy.Terms.shape(error, fields: [:key, :term])
      "KeyError(key: :name)"

  The option `:depth` limits the number of levels:

      iex> Shoddy.Terms.shape({:a, {:b, {:c, 1}}}, depth: 2)
      "{:a, {:b, tuple(2)}}"
  """
  @spec shape(term(), keyword()) :: String.t()
  def shape(term, opts \\ []) when is_list(opts) do
    opts = Keyword.validate!(opts, fields: [:reason], depth: 4)
    fields = fields!(Keyword.fetch!(opts, :fields))
    depth = depth!(Keyword.fetch!(opts, :depth))

    shape(term, fields, depth)
  end

  defp fields!(fields) when is_list(fields) do
    if Enum.all?(fields, &is_atom/1),
      do: fields,
      else: Shoddy.Option.invalid!(:fields, "a list of atoms", fields)
  end

  defp fields!(other), do: Shoddy.Option.invalid!(:fields, "a list of atoms", other)

  defp depth!(depth) when is_integer(depth) and depth >= 0, do: depth
  defp depth!(other), do: Shoddy.Option.invalid!(:depth, "a non-negative integer", other)

  # The third argument is the number of levels that the function can still
  # open.
  defp shape(term, _fields, _levels) when is_atom(term), do: inspect(term)
  defp shape(term, _fields, _levels) when is_binary(term), do: "binary"
  defp shape(term, _fields, _levels) when is_bitstring(term), do: "bitstring"
  defp shape(term, _fields, _levels) when is_integer(term), do: "integer"
  defp shape(term, _fields, _levels) when is_float(term), do: "float"
  defp shape(term, _fields, _levels) when is_pid(term), do: "pid"
  defp shape(term, _fields, _levels) when is_reference(term), do: "reference"
  defp shape(term, _fields, _levels) when is_port(term), do: "port"
  defp shape(term, _fields, _levels) when is_function(term), do: "function"
  defp shape([], _fields, _levels), do: "[]"

  defp shape(term, fields, levels) when is_list(term) do
    if exceptions?(term), do: exceptions(term, fields, levels), else: "list"
  end

  defp shape(%module{__exception__: true}, _fields, 0), do: inspect(module)
  defp shape(%{__exception__: true} = error, fields, levels), do: exception(error, fields, levels)
  defp shape(%module{}, _fields, _levels), do: "%#{inspect(module)}{}"
  defp shape(term, _fields, _levels) when is_map(term), do: "map(#{map_size(term)})"

  defp shape(term, fields, levels) when is_tuple(term) and levels > 0 do
    "{" <> (term |> Tuple.to_list() |> Enum.map_join(", ", &shape(&1, fields, levels - 1))) <> "}"
  end

  defp shape(term, _fields, _levels) when is_tuple(term), do: "tuple(#{tuple_size(term)})"

  # A proper list whose elements are all exceptions. An improper list is
  # never such a list.
  defp exceptions?(list) do
    proper_list?(list) and Enum.all?(list, &match?(%{__exception__: true}, &1))
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp exceptions(errors, fields, levels) do
    shown = errors |> Enum.take(@most_errors) |> Enum.map_join(", ", &shape(&1, fields, levels))
    rest = length(errors) - @most_errors

    if rest > 0, do: "[#{shown}, and #{rest} more]", else: "[#{shown}]"
  end

  defp exception(%module{} = error, fields, levels) do
    shown = for field <- fields, text = field(Map.get(error, field), fields, levels - 1), do: "#{field}: #{text}"

    case shown do
      [] -> inspect(module)
      _shown -> "#{inspect(module)}(#{Enum.join(shown, ", ")})"
    end
  end

  defp field(value, _fields, _levels) when value in [nil, true, false], do: nil
  defp field(value, _fields, _levels) when is_atom(value), do: inspect(value)
  defp field(value, fields, levels) when is_tuple(value), do: shape(value, fields, levels)
  defp field(%{__exception__: true} = value, fields, levels), do: shape(value, fields, levels)

  defp field([_ | _] = value, fields, levels) do
    if exceptions?(value), do: exceptions(value, fields, levels)
  end

  defp field(_value, _fields, _levels), do: nil
end
