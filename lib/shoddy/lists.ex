defmodule Shoddy.Lists do
  @moduledoc """
  Functions that operate on lists and add to the standard `List` module.

  Each function takes the list as the first argument. Thus you can use these
  functions in a pipeline.

  The name of this module is `Lists`, in the plural. Thus the alias `Lists`
  does not hide the standard `List` module.
  """

  @scan_length 1024

  @doc """
  Returns each element that occurs more than one time in a list.

  The result contains each such element one time, in the order of its first
  occurrence in the list. If no element occurs more than one time, the result
  is an empty list.

  This function compares two elements with the strict equality operator
  `===/2`, as `Enum.uniq/1` does. Thus the integer `1` and the float `1.0` are
  two different elements.

  `list -- Enum.uniq(list)` is different. It contains an element one time
  for each extra occurrence, so an element that occurs three times occurs two
  times in its result.

  ## Examples

      iex> Shoddy.Lists.duplicates([:a, :b, :a, :c, :b, :a])
      [:a, :b]

      iex> Shoddy.Lists.duplicates([:a, :b, :c])
      []

      iex> Shoddy.Lists.duplicates([])
      []

  The function compares with `===/2`:

      iex> Shoddy.Lists.duplicates([1, 1.0, 2, 2])
      [2]

  Use the function to check a list for duplicates:

      iex> ["ada@example.com", "grace@example.com", "ada@example.com"]
      ...> |> Shoddy.Lists.duplicates()
      ...> |> Shoddy.then_if(&match?([_ | _], &1), &{:error, {:duplicate_emails, &1}})
      {:error, {:duplicate_emails, ["ada@example.com"]}}
  """
  @spec duplicates([element]) :: [element] when element: var
  def duplicates(list) when is_list(list) do
    {_seen, repeated} =
      Enum.reduce(list, {MapSet.new(), MapSet.new()}, fn element, {seen, repeated} ->
        if MapSet.member?(seen, element),
          do: {seen, MapSet.put(repeated, element)},
          else: {MapSet.put(seen, element), repeated}
      end)

    {result, _pending} =
      Enum.reduce(list, {[], repeated}, fn element, {result, pending} ->
        if MapSet.member?(pending, element),
          do: {[element | result], MapSet.delete(pending, element)},
          else: {result, pending}
      end)

    Enum.reverse(result)
  end

  @doc """
  Returns the elements of a list that have the same key as another element.

  `key_fun` returns the key of an element. The result is a map. It has an
  entry for each key that more than one element has. The value of that entry
  is the list of these elements, in the order of the input. A key that
  only one element has is not in the map. If no two elements have the same
  key, the result is an empty map.

  This function compares two keys with the strict equality operator `===/2`,
  as the keys of a map do. Thus the integer `1` and the float `1.0` are two
  different keys.

  Use this function to tell which elements have the same value in a field.
  `duplicates/1` on the values of the field tells only the value.

  ## Examples

      iex> users = [
      ...>   %{name: "Ada", email: "ada@example.com"},
      ...>   %{name: "Grace", email: "grace@example.com"},
      ...>   %{name: "A. Lovelace", email: "ada@example.com"}
      ...> ]
      iex> Shoddy.Lists.duplicates_by(users, & &1.email)
      %{
        "ada@example.com" => [
          %{name: "Ada", email: "ada@example.com"},
          %{name: "A. Lovelace", email: "ada@example.com"}
        ]
      }

      iex> Shoddy.Lists.duplicates_by(["a", "B", "b", "c"], &String.downcase/1)
      %{"b" => ["B", "b"]}

      iex> Shoddy.Lists.duplicates_by([1, 2, 3], & &1)
      %{}

  The function compares the keys with `===/2`:

      iex> Shoddy.Lists.duplicates_by([1, 1.0], & &1)
      %{}
  """
  @spec duplicates_by([element], (element -> key)) :: %{optional(key) => [element, ...]}
        when element: var, key: var
  def duplicates_by(list, key_fun) when is_list(list) and is_function(key_fun, 1) do
    list
    |> Enum.group_by(key_fun)
    |> Map.filter(&match?({_key, [_, _ | _]}, &1))
  end

  @doc """
  Returns `true` if an element occurs more than one time in a list.

  This function compares two elements with the strict equality operator
  `===/2`, as `duplicates/1` does. Thus the integer `1` and the float `1.0`
  are two different elements.

  This function is faster than `duplicates(list) != []`. If the second
  occurrence of an element is in the first 1024 elements, the function stops
  at that occurrence.

  ## Examples

      iex> Shoddy.Lists.has_duplicates?([:a, :b, :a])
      true

      iex> Shoddy.Lists.has_duplicates?([:a, :b, :c])
      false

      iex> Shoddy.Lists.has_duplicates?([])
      false

  The function compares with `===/2`:

      iex> Shoddy.Lists.has_duplicates?([1, 1.0])
      false
  """
  @spec has_duplicates?(list()) :: boolean()
  def has_duplicates?(list) when is_list(list), do: scan(list, %{}, @scan_length, list)

  defp scan([], _seen, _remaining, _list), do: false
  defp scan(_rest, _seen, 0, list), do: map_size(:maps.from_keys(list, [])) != length(list)
  defp scan([element | _rest], seen, _remaining, _list) when is_map_key(seen, element), do: true

  defp scan([element | rest], seen, remaining, list), do: scan(rest, Map.put(seen, element, []), remaining - 1, list)

  @doc """
  Returns the only element of a list in an ok tuple.

  The function returns an error tuple if the list does not contain exactly
  one element:

  - `{:error, :empty}` for an empty list.
  - `{:error, {:many, count}}` for a list of more than one element. `count`
    is the number of elements.

  `List.first/1` and `hd/1` ignore the other elements, and `List.first/1`
  returns `nil` for an empty list. Use this function if more than one element
  is an error, for example for a query that must find one record.

  ## Examples

      iex> Shoddy.Lists.single([:a])
      {:ok, :a}

      iex> Shoddy.Lists.single([])
      {:error, :empty}

      iex> Shoddy.Lists.single([:a, :b, :c])
      {:error, {:many, 3}}

  The element can be `nil` or `false`:

      iex> Shoddy.Lists.single([nil])
      {:ok, nil}

      iex> Shoddy.Lists.single([false])
      {:ok, false}

  Use the function in a pipeline of results:

      iex> [%{id: 1, email: "ada@example.com"}, %{id: 2, email: "grace@example.com"}]
      ...> |> Enum.filter(&(&1.email == "ada@example.com"))
      ...> |> Shoddy.Lists.single()
      ...> |> Shoddy.Result.map_ok(& &1.id)
      {:ok, 1}
  """
  @spec single([element]) :: {:ok, element} | {:error, :empty | {:many, pos_integer()}}
        when element: var
  def single([element]), do: {:ok, element}
  def single([]), do: {:error, :empty}
  def single([_, _ | _] = list), do: {:error, {:many, length(list)}}
end
