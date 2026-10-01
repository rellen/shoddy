defmodule Shoddy.Maps do
  @moduledoc """
  Functions that operate on maps and add to the standard `Map` module.

  Each function takes the map as the first argument, as in the `Map` module.
  Thus you can use these functions in a pipeline:

      %{}
      |> Shoddy.Maps.put_if(:name, params["name"])
      |> Shoddy.Maps.put_if(:email, params["email"])

  The name of this module is `Maps`, in the plural. Thus the alias `Maps`
  does not hide the standard `Map` module.

  A struct is also a map, but it has a fixed set of fields. For a struct,
  `put_if/3` and `put_present/3` accept only a key that is a field of the
  struct. They raise `KeyError` for another key, as the update syntax
  `%{struct | key: value}` does. They raise this error also if they do not put
  the value. Thus a wrong key always causes an error.
  """

  @doc """
  Puts a value into a map if the value is truthy.

  A truthy value is a value that is not `nil` and not `false`. A falsy value
  is `nil` or `false`.

  If `value` is falsy, this function returns the map with no change. An entry
  that is already in the map under `key` also stays with no change. This
  function does not replace that entry and does not remove it.

  Use this function to build a map from optional data. The map does not get
  an entry for a field that is absent, and it does not get a `nil` value for
  that field.

  For a struct, `key` must be a field of the struct. This function raises
  `KeyError` for another key, also if it does not put the value.

  ## Examples

  The function puts a truthy value into the map:

      iex> Shoddy.Maps.put_if(%{}, :name, "Ada")
      %{name: "Ada"}

      iex> Shoddy.Maps.put_if(%{a: 1}, :b, 2)
      %{a: 1, b: 2}

  The function ignores a falsy value:

      iex> Shoddy.Maps.put_if(%{a: 1}, :b, nil)
      %{a: 1}

      iex> Shoddy.Maps.put_if(%{a: 1}, :b, false)
      %{a: 1}

  Only a truthy value replaces an entry that is already in the map:

      iex> Shoddy.Maps.put_if(%{a: 1}, :a, 2)
      %{a: 2}

      iex> Shoddy.Maps.put_if(%{a: 1}, :a, nil)
      %{a: 1}

  In Elixir, zero, an empty collection, and an empty string are truthy. Thus
  the function puts them into the map:

      iex> Shoddy.Maps.put_if(%{}, :count, 0)
      %{count: 0}

      iex> Shoddy.Maps.put_if(%{}, :items, [])
      %{items: []}

      iex> Shoddy.Maps.put_if(%{}, :name, "")
      %{name: ""}

  This example builds a map of optional fields in a pipeline:

      iex> params = %{"name" => "Ada", "email" => nil}
      iex> %{}
      ...> |> Shoddy.Maps.put_if(:name, params["name"])
      ...> |> Shoddy.Maps.put_if(:email, params["email"])
      %{name: "Ada"}

  The function puts a value into a field of a struct:

      iex> Shoddy.Maps.put_if(%URI{host: "example.com"}, :port, 443).port
      443
  """
  @spec put_if(map(), key, value) :: map() when key: any(), value: any()
  def put_if(map, key, value) when is_map(map), do: put_when(map, key, value, value not in [nil, false])

  @doc """
  Puts a value into a map if the value is not `nil`.

  If `value` is `nil`, this function returns the map with no change. An entry
  that is already in the map under `key` also stays with no change.

  This function is different from `put_if/3` for one value only.
  `put_if/3` ignores `false`, but this function puts `false` into the map.
  Use this function for a field that can be `false`, such as a boolean
  option.

  For a struct, `key` must be a field of the struct. This function raises
  `KeyError` for another key, also if it does not put the value.

  ## Examples

  The function puts a value that is not `nil` into the map:

      iex> Shoddy.Maps.put_present(%{}, :name, "Ada")
      %{name: "Ada"}

      iex> Shoddy.Maps.put_present(%{name: "Ada"}, :subscribed, false)
      %{name: "Ada", subscribed: false}

  The function ignores `nil`:

      iex> Shoddy.Maps.put_present(%{name: "Ada"}, :email, nil)
      %{name: "Ada"}

      iex> Shoddy.Maps.put_present(%{email: "ada@example.com"}, :email, nil)
      %{email: "ada@example.com"}

  This example builds a map of optional fields in a pipeline:

      iex> params = %{"name" => "Ada", "email" => nil, "subscribed" => false}
      iex> %{}
      ...> |> Shoddy.Maps.put_present(:name, params["name"])
      ...> |> Shoddy.Maps.put_present(:email, params["email"])
      ...> |> Shoddy.Maps.put_present(:subscribed, params["subscribed"])
      %{name: "Ada", subscribed: false}

  The function puts a value into a field of a struct:

      iex> Shoddy.Maps.put_present(%URI{host: "example.com"}, :port, 443).port
      443
  """
  @spec put_present(map(), key, value) :: map() when key: any(), value: any()
  def put_present(map, key, value) when is_map(map), do: put_when(map, key, value, not is_nil(value))

  @doc """
  Returns the value of a key, or a default if the value is absent or `nil`.

  If `map` has no entry for `key`, or the value of the entry is `nil`, this
  function returns `default`. It returns `false` with no change.

  `Map.get(map, key, default)` is different. It returns `nil` for an entry
  with the value `nil`. `Map.get(map, key) || default` is also different. It
  returns the default also for `false`.

  Use this function for data where an absent key and the value `nil` have
  the same meaning, such as decoded JSON or optional fields.

  ## Examples

      iex> Shoddy.Maps.get_present(%{tags: [:a]}, :tags, [])
      [:a]

      iex> Shoddy.Maps.get_present(%{}, :tags, [])
      []

      iex> Shoddy.Maps.get_present(%{tags: nil}, :tags, [])
      []

  `Map.get/3` returns `nil` for an entry with the value `nil`:

      iex> Map.get(%{tags: nil}, :tags, [])
      nil

  The function returns `false` with no change:

      iex> Shoddy.Maps.get_present(%{active: false}, :active, true)
      false

  The function also reads a field of a struct:

      iex> Shoddy.Maps.get_present(%URI{port: nil}, :port, 443)
      443
  """
  @spec get_present(map(), key, default) :: value | default when key: any(), value: any(), default: any()
  def get_present(map, key, default) when is_map(map) do
    case map do
      %{^key => value} when not is_nil(value) -> value
      _other -> default
    end
  end

  @doc """
  Takes keys from a map, and gives each key a new name.

  `mapping` is a map from each key to take to its new name. The result
  contains only the keys of `mapping`. A key that is not in `map` does not
  get an entry. A key with the value `nil` gets an entry with `nil`.

  Use this function to convert the parameters of a web form, which have
  string keys, into a map with atom keys. Only the new names in `mapping`
  become keys, so the input cannot make new atoms.

  The result is always a plain map, also if `map` is a struct.

  This function raises `ArgumentError` if more than one key of `mapping` has
  the same new name. The result would then depend on the order of the keys.
  This function also raises `ArgumentError` if a new name is `:__struct__`.
  The result would then be a struct.

  `mapping` cannot be a struct. For a struct, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> params = %{"name" => "Ada", "email" => "ada@example.com", "admin" => "true"}
      iex> Shoddy.Maps.take_as(params, %{"name" => :name, "email" => :email})
      %{name: "Ada", email: "ada@example.com"}

  A key that is not in the map does not get an entry:

      iex> Shoddy.Maps.take_as(%{"name" => "Ada"}, %{"name" => :name, "email" => :email})
      %{name: "Ada"}

  A key with the value `nil` gets an entry:

      iex> Shoddy.Maps.take_as(%{"email" => nil}, %{"email" => :email})
      %{email: nil}

  Use the function with `put_if/3` in a pipeline:

      iex> params = %{"name" => "Ada", "age" => "36"}
      iex> params
      ...> |> Shoddy.Maps.take_as(%{"name" => :name})
      ...> |> Shoddy.Maps.put_if(:age, Shoddy.then_if(params["age"], &String.to_integer/1))
      %{name: "Ada", age: 36}
  """
  @spec take_as(map(), %{optional(key) => new_key}) :: %{optional(new_key) => any()}
        when key: any(), new_key: any()
  def take_as(map, mapping) when is_map(map) and is_non_struct_map(mapping) do
    ensure_no_struct_name!(mapping)
    ensure_unique_names!(mapping)

    for {key, new_key} <- mapping, {:ok, value} <- [Map.fetch(map, key)], into: %{} do
      {new_key, value}
    end
  end

  defp ensure_no_struct_name!(mapping) do
    mapping
    |> Map.values()
    |> Enum.member?(:__struct__)
    |> Shoddy.then_if(fn true ->
      raise ArgumentError, "a new name of the mapping cannot be :__struct__, because the result would then be a struct"
    end)
  end

  defp ensure_unique_names!(mapping) do
    mapping
    |> Map.values()
    |> Shoddy.Lists.has_duplicates?()
    |> Shoddy.then_if(fn true ->
      raise ArgumentError,
            "more than one key of the mapping has the same new name: " <> describe_collisions(mapping)
    end)
  end

  defp describe_collisions(mapping) do
    mapping
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
    |> Enum.filter(&match?({_new_key, [_, _ | _]}, &1))
    |> Enum.sort()
    |> Enum.map_join("; ", fn {new_key, keys} ->
      "#{inspect(new_key)} for the keys #{inspect(Enum.sort(keys))}"
    end)
  end

  @doc """
  Merges two maps, and merges each nested map of the same key.

  For a key that is in the two maps, the value comes from `right`. But if the
  two values are plain maps, the function merges them in the same way. Thus a
  nested map of `right` changes only its keys of the nested map of `left`.

  The function merges only plain maps. `right` replaces each other value,
  also if the two values are structs, lists or keyword lists. A value of
  `nil` in `right` also replaces the value of `left`. An empty map in `right`
  keeps the nested map of `left` with no change.

  The two arguments must be plain maps. For a struct, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> defaults = %{log: %{level: :info, format: :text}, port: 4000}
      iex> Shoddy.Maps.deep_merge(defaults, %{log: %{level: :debug}})
      %{log: %{level: :debug, format: :text}, port: 4000}

  `Map.merge/2` replaces the nested map:

      iex> Map.merge(%{log: %{level: :info, format: :text}}, %{log: %{level: :debug}})
      %{log: %{level: :debug}}

  The function does not merge a list, a keyword list or a struct:

      iex> Shoddy.Maps.deep_merge(%{tags: [:a], opts: [x: 1]}, %{tags: [:b], opts: [y: 2]})
      %{tags: [:b], opts: [y: 2]}

      iex> Shoddy.Maps.deep_merge(%{date: ~D[2024-01-01]}, %{date: ~D[2025-06-30]})
      %{date: ~D[2025-06-30]}

  A value that is not a map replaces a map, and a map replaces such a value:

      iex> Shoddy.Maps.deep_merge(%{log: %{level: :info}}, %{log: nil})
      %{log: nil}

      iex> Shoddy.Maps.deep_merge(%{log: false}, %{log: %{level: :info}})
      %{log: %{level: :info}}
  """
  @spec deep_merge(map(), map()) :: map()
  def deep_merge(left, right) when is_non_struct_map(left) and is_non_struct_map(right) do
    Map.merge(left, right, &merge_value/3)
  end

  defp merge_value(_key, left, right) when is_non_struct_map(left) and is_non_struct_map(right),
    do: deep_merge(left, right)

  defp merge_value(_key, _left, right), do: right

  defp put_when(struct, key, _value, _put?) when is_struct(struct) and not is_map_key(struct, key) do
    raise KeyError, key: key, term: struct
  end

  defp put_when(map, key, value, true), do: Map.put(map, key, value)
  defp put_when(map, _key, _value, false), do: map
end
