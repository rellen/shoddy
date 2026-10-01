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
  Returns a map from the key of each element to the element.

  `key_fun` returns the key of an element. Use this function to find
  records by a key, such as an ID, many times. A lookup in the map is faster
  than `Enum.find/2` on the list.

  Each key must be unique. This function raises `ArgumentError` if more than
  one element has the same key. The message tells each such key.
  `Map.new(list, &{&1.id, &1})` is different: it keeps the last of these
  elements, and it does not tell you about the others.

  This function compares two keys with the strict equality operator `===/2`,
  as the keys of a map do. Thus the integer `1` and the float `1.0` are two
  different keys.

  ## Examples

      iex> users = [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
      iex> Shoddy.Lists.index_by(users, & &1.id)
      %{1 => %{id: 1, name: "Ada"}, 2 => %{id: 2, name: "Grace"}}

      iex> Shoddy.Lists.index_by([], & &1.id)
      %{}

  The function raises an error for a key that is not unique:

      iex> Shoddy.Lists.index_by([%{id: 1}, %{id: 1}], & &1.id)
      ** (ArgumentError) more than one element has the same key: [1]

  Use the map to find each record by its key:

      iex> users = [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
      iex> by_id = Shoddy.Lists.index_by(users, & &1.id)
      iex> Enum.map([2, 1], &by_id[&1].name)
      ["Grace", "Ada"]
  """
  @spec index_by([element], (element -> key)) :: %{optional(key) => element}
        when element: var, key: var
  def index_by(list, key_fun) when is_list(list) and is_function(key_fun, 1) do
    index = Map.new(list, &{key_fun.(&1), &1})

    if map_size(index) == length(list) do
      index
    else
      keys = list |> Enum.map(key_fun) |> duplicates()
      raise ArgumentError, "more than one element has the same key: #{inspect(keys)}"
    end
  end

  @doc """
  Puts the elements of a list into groups by key, and keeps the order.

  `key_fun` returns the key of an element. The result is a list of
  `{key, elements}` tuples. The groups are in the order of the first
  element of each key, and the elements of a group are in the order of the
  input.

  `Enum.group_by/2` returns a map. A map has no order that you can use, so
  the groups can change their order. `Enum.chunk_by/2` keeps the order, but
  it makes a new group each time the key changes. Use this function to show
  groups in the order of the data, such as messages by day.

  This function compares two keys with the strict equality operator `===/2`.

  ## Examples

      iex> Shoddy.Lists.group_by_in_order(["b1", "a1", "b2", "c1", "a2"], &String.first/1)
      [{"b", ["b1", "b2"]}, {"a", ["a1", "a2"]}, {"c", ["c1"]}]

      iex> Shoddy.Lists.group_by_in_order([], &String.first/1)
      []

  `Enum.chunk_by/2` makes a new group each time the key changes:

      iex> Enum.chunk_by(["b1", "a1", "b2"], &String.first/1)
      [["b1"], ["a1"], ["b2"]]

      iex> Shoddy.Lists.group_by_in_order(["b1", "a1", "b2"], &String.first/1)
      [{"b", ["b1", "b2"]}, {"a", ["a1"]}]
  """
  @spec group_by_in_order([element], (element -> key)) :: [{key, [element, ...]}]
        when element: var, key: var
  def group_by_in_order(list, key_fun) when is_list(list) and is_function(key_fun, 1) do
    {keys, groups} =
      Enum.reduce(list, {[], %{}}, fn element, {keys, groups} ->
        key = key_fun.(element)

        case groups do
          %{^key => elements} -> {keys, %{groups | key => [element | elements]}}
          _new_key -> {[key | keys], Map.put(groups, key, [element])}
        end
      end)

    keys
    |> Enum.reverse()
    |> Enum.map(&{&1, Enum.reverse(Map.fetch!(groups, &1))})
  end

  @doc """
  Replaces the element with the same key, or adds the element to the list.

  `key_fun` returns the key of an element. If an element of `list` has the
  same key as `element`, this function puts `element` at its position. If
  more than one element has that key, it replaces only the first. If no
  element has that key, it adds `element` to the list.

  Use this function to apply a change to a list of records. An example is a
  message that tells about a new or a changed record.

  This function compares two keys with the strict equality operator `===/2`.

  ## Options

    * `:at` - The place where the function adds a new element: `:end` or
      `:start`. The default is `:end`. The option has no effect on a
      replacement.

  This function raises `ArgumentError` for an unknown option and for
  another value of `:at`.

  ## Examples

      iex> users = [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
      iex> Shoddy.Lists.upsert_by(users, & &1.id, %{id: 2, name: "Grace Hopper"})
      [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace Hopper"}]
      iex> Shoddy.Lists.upsert_by(users, & &1.id, %{id: 3, name: "Alan"})
      [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}, %{id: 3, name: "Alan"}]
      iex> Shoddy.Lists.upsert_by(users, & &1.id, %{id: 3, name: "Alan"}, at: :start)
      [%{id: 3, name: "Alan"}, %{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
  """
  @spec upsert_by([element], (element -> any()), element, keyword()) :: [element, ...] when element: var
  def upsert_by(list, key_fun, element, opts \\ []) when is_list(list) and is_function(key_fun, 1) and is_list(opts) do
    at = at!(opts)
    key = key_fun.(element)

    case Enum.find_index(list, &(key_fun.(&1) === key)) do
      nil when at == :start -> [element | list]
      nil -> list ++ [element]
      index -> List.replace_at(list, index, element)
    end
  end

  defp at!(opts) do
    opts
    |> Keyword.validate!(at: :end)
    |> Keyword.fetch!(:at)
    |> case do
      at when at in [:end, :start] -> at
      other -> raise ArgumentError, "invalid value for :at option: expected :end or :start, got: #{inspect(other)}"
    end
  end

  @doc """
  Sorts a list by more than one key, and gives each key its own direction.

  `keys` is a list. The function compares two elements by the first key. If
  the two values are equal, it compares them by the next key, and so on.
  Elements with equal values for each key stay in the order of the input.

  Each element of `keys` is one of these forms:

    * `fun` - A function that returns the key. The direction is ascending.
    * `{direction, fun}` - The direction is `:asc` or `:desc`.
    * `{direction, fun, module}` - The function compares the values with
      `module.compare/2`, for example `Date` or `DateTime`.

  Use a module for each struct that has an order, such as a date or a time.
  The operators `<` and `>` compare the fields of a struct, so they give a
  wrong order for these values. `Enum.sort_by/3` accepts a module too, but
  only for one key.

  This function raises `ArgumentError` for an element of `keys` that is not
  one of these forms, and for a module that does not export `compare/2`.

  ## Examples

      iex> people = [%{name: "Ada", age: 36}, %{name: "Alan", age: 41}, %{name: "Grace", age: 36}]
      iex> Shoddy.Lists.sort_by_keys(people, [{:desc, & &1.age}, & &1.name])
      [%{name: "Alan", age: 41}, %{name: "Ada", age: 36}, %{name: "Grace", age: 36}]

  Give a module for a date:

      iex> events = [%{on: ~D[2024-02-01], title: "B"}, %{on: ~D[2024-01-31], title: "A"}]
      iex> Shoddy.Lists.sort_by_keys(events, [{:asc, & &1.on, Date}])
      [%{on: ~D[2024-01-31], title: "A"}, %{on: ~D[2024-02-01], title: "B"}]
  """
  @spec sort_by_keys([element], [key_spec, ...]) :: [element]
        when element: var,
             key_spec:
               (element -> any())
               | {:asc | :desc, (element -> any())}
               | {:asc | :desc, (element -> any()), module()}
  def sort_by_keys(list, [_ | _] = keys) when is_list(list) do
    specs = Enum.map(keys, &key_spec!/1)

    Enum.sort_by(
      list,
      fn element -> Enum.map(specs, fn {_direction, fun, _module} -> fun.(element) end) end,
      &in_order?(&1, &2, specs)
    )
  end

  defp key_spec!(fun) when is_function(fun, 1), do: {:asc, fun, nil}
  defp key_spec!({direction, fun}) when direction in [:asc, :desc] and is_function(fun, 1), do: {direction, fun, nil}

  defp key_spec!({direction, fun, module} = spec)
       when direction in [:asc, :desc] and is_function(fun, 1) and is_atom(module) do
    if Code.ensure_loaded?(module) and function_exported?(module, :compare, 2) do
      spec
    else
      raise ArgumentError, "the module #{inspect(module)} does not export compare/2"
    end
  end

  defp key_spec!(other) do
    raise ArgumentError,
          "invalid key: expected a function of arity 1, {direction, fun} or {direction, fun, module}, " <>
            "got: #{inspect(other)}"
  end

  defp in_order?([], [], []), do: true

  defp in_order?([left | lefts], [right | rights], [{direction, _fun, module} | specs]) do
    case {compare(left, right, module), direction} do
      {:eq, _direction} -> in_order?(lefts, rights, specs)
      {:lt, :asc} -> true
      {:gt, :desc} -> true
      _other -> false
    end
  end

  defp compare(left, right, nil) when left < right, do: :lt
  defp compare(left, right, nil) when left > right, do: :gt
  defp compare(_left, _right, nil), do: :eq
  defp compare(left, right, module), do: module.compare(left, right)

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
