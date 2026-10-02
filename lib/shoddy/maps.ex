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
  `put_if/3`, `put_present/3` and `put_path/3` accept only a key that is a
  field of the struct. They raise `KeyError` for another key, as the update
  syntax `%{struct | key: value}` does. `put_if/3` and `put_present/3` raise
  this error also if they do not put the value. Thus a wrong key always
  causes an error.

  The key `:__struct__` is not a field. A new value for it would change the
  type of the struct, so these functions raise `KeyError` for it too.
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
    if :__struct__ in Map.values(mapping) do
      raise ArgumentError, "a new name of the mapping cannot be :__struct__, because the result would then be a struct"
    end
  end

  defp ensure_unique_names!(mapping) do
    if mapping |> Map.values() |> Shoddy.Lists.has_duplicates?() do
      raise ArgumentError, "more than one key of the mapping has the same new name: " <> describe_collisions(mapping)
    end
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

  @doc """
  Applies a function to each value of a map, and keeps the keys.

  `fun` receives the value only. To use the key too, call `Map.new/2` with a
  function that receives the key-value tuple.

  The map must be a plain map. A struct has a fixed set of fields, and a
  change to each field at one time is not a correct operation on it. For a
  struct, this function raises `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.map_values(%{a: 1, b: 2}, &(&1 * 10))
      %{a: 10, b: 20}

      iex> Shoddy.Maps.map_values(%{}, &(&1 * 10))
      %{}

  This example counts the elements of each group:

      iex> ["apple", "avocado", "banana"]
      ...> |> Enum.group_by(&String.first/1)
      ...> |> Shoddy.Maps.map_values(&length/1)
      %{"a" => 2, "b" => 1}
  """
  @spec map_values(%{optional(key) => value}, (value -> new_value)) :: %{optional(key) => new_value}
        when key: any(), value: any(), new_value: any()
  def map_values(map, fun) when is_non_struct_map(map) and is_function(fun, 1) do
    Map.new(map, fn {key, value} -> {key, fun.(value)} end)
  end

  @doc """
  Applies a function to each key of a map, and keeps the values.

  `fun` receives the key only. If `fun` returns the same new key for more
  than one key, the result could keep only one of their values. Thus this
  function raises `ArgumentError` for such keys. The message tells each new
  key and the keys that gave it.

  The map must be a plain map. For a struct, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.map_keys(%{"name" => "Ada", "email" => "ada@example.com"}, &String.upcase/1)
      %{"NAME" => "Ada", "EMAIL" => "ada@example.com"}

      iex> Shoddy.Maps.map_keys(%{a: 1, b: 2}, &Atom.to_string/1)
      %{"a" => 1, "b" => 2}

  The function raises an error if two keys get the same new key:

      iex> Shoddy.Maps.map_keys(%{"a" => 1, "A" => 2}, &String.downcase/1)
      ** (ArgumentError) more than one key has the same new key: "a" for the keys ["A", "a"]
  """
  @spec map_keys(%{optional(key) => value}, (key -> new_key)) :: %{optional(new_key) => value}
        when key: any(), value: any(), new_key: any()
  def map_keys(map, fun) when is_non_struct_map(map) and is_function(fun, 1) do
    result = Map.new(map, fn {key, value} -> {fun.(key), value} end)

    if map_size(result) == map_size(map) do
      result
    else
      mapping = Map.new(map, fn {key, _value} -> {key, fun.(key)} end)
      raise ArgumentError, "more than one key has the same new key: " <> describe_collisions(mapping)
    end
  end

  @doc """
  Puts a value into a nested map, and makes each map on the path that is absent.

  `path` is a list of keys. The last key gets the value. For each other key,
  this function goes into the map under that key. If the key is absent, or
  its value is `nil`, this function puts an empty map there first.

  `put_in/3` is different. It raises `ArgumentError` if a map on the path is
  absent.

  If a value on the path is not a map and not `nil`, this function raises
  `ArgumentError`. The message tells the path to that value. A struct on the
  path accepts only its fields as keys, as in `put_if/3`. For another key,
  this function raises `KeyError`.

  ## Examples

      iex> Shoddy.Maps.put_path(%{}, [:log, :level], :debug)
      %{log: %{level: :debug}}

      iex> Shoddy.Maps.put_path(%{log: %{format: :text}}, [:log, :level], :debug)
      %{log: %{format: :text, level: :debug}}

  The function replaces `nil` with a map:

      iex> Shoddy.Maps.put_path(%{log: nil}, [:log, :level], :debug)
      %{log: %{level: :debug}}

  A path of one key puts the value into the map:

      iex> Shoddy.Maps.put_path(%{a: 1}, [:b], 2)
      %{a: 1, b: 2}

  The function raises an error for a value on the path that is not a map:

      iex> Shoddy.Maps.put_path(%{log: :off}, [:log, :level], :debug)
      ** (ArgumentError) the value at the path [:log] is not a map: :off
  """
  @spec put_path(map(), [any(), ...], any()) :: map()
  def put_path(map, [_ | _] = path, value) when is_map(map), do: put_path_at(map, path, value, [])

  defp put_path_at(map, [key], value, _above), do: put_when(map, key, value, true)

  defp put_path_at(map, [key | rest], value, above) do
    child =
      case map do
        %{^key => child} when is_map(child) ->
          child

        %{^key => other} when not is_nil(other) ->
          raise ArgumentError,
                "the value at the path #{inspect(Enum.reverse([key | above]))} is not a map: #{inspect(other)}"

        _absent_or_nil ->
          %{}
      end

    put_when(map, key, put_path_at(child, rest, value, [key | above]), true)
  end

  @doc """
  Takes the given keys from a map, or returns the keys that are absent.

  If `map` has each key of `keys`, this function returns `{:ok, map}` with
  only those keys. Otherwise, it returns `{:error, {:missing_keys, missing}}`.
  `missing` lists each absent key one time, in the order of `keys`.

  A key with the value `nil` is present, as for `Map.fetch/2`. To treat
  `nil` as absent, remove such entries first, for example with
  `Map.reject/2`.

  `Map.take/2` is different. It ignores each absent key, so the caller cannot
  tell that a key is missing.

  ## Examples

      iex> params = %{"name" => "Ada", "email" => "ada@example.com", "admin" => "true"}
      iex> Shoddy.Maps.fetch_keys(params, ["name", "email"])
      {:ok, %{"name" => "Ada", "email" => "ada@example.com"}}

      iex> Shoddy.Maps.fetch_keys(%{"name" => "Ada"}, ["name", "email", "age"])
      {:error, {:missing_keys, ["email", "age"]}}

  A key with the value `nil` is present:

      iex> Shoddy.Maps.fetch_keys(%{"name" => nil}, ["name"])
      {:ok, %{"name" => nil}}
  """
  @spec fetch_keys(map(), [key]) :: {:ok, %{optional(key) => any()}} | {:error, {:missing_keys, [key, ...]}}
        when key: any()
  def fetch_keys(map, keys) when is_map(map) and is_list(keys) do
    keys
    |> Enum.reject(&Map.has_key?(map, &1))
    |> Enum.uniq()
    |> case do
      [] -> {:ok, Map.take(map, keys)}
      missing -> {:error, {:missing_keys, missing}}
    end
  end

  @doc """
  Removes each entry with the value `nil`.

  Use this function before you send a map to a system that treats `null` and
  an absent key in different ways. To build such a map from the start, use
  `put_present/3`.

  The function keeps `false`. The map must be a plain map. For a struct, it
  raises `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.compact(%{name: "Ada", email: nil, admin: false})
      %{name: "Ada", admin: false}

      iex> Shoddy.Maps.compact(%{})
      %{}
  """
  @spec compact(%{optional(key) => value | nil}) :: %{optional(key) => value} when key: any(), value: any()
  def compact(map) when is_non_struct_map(map), do: Map.reject(map, fn {_key, value} -> is_nil(value) end)

  @doc """
  Adds a number to the value of a key, or puts the number for an absent key.

  The default amount is `1`. For an absent key, the new value is the amount
  itself. `Map.update(map, key, 1, &(&1 + by))` is a usual way to write this
  operation, and its initial value `1` is wrong for each other amount.

  The value of the key must be a number. For another value, this function
  raises `ArithmeticError`. The map must be a plain map. For a struct, it
  raises `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.increment(%{apple: 2}, :apple)
      %{apple: 3}

      iex> Shoddy.Maps.increment(%{}, :pear, 5)
      %{pear: 5}

  This example counts the words of a text:

      iex> "a b a c a"
      ...> |> String.split()
      ...> |> Enum.reduce(%{}, &Shoddy.Maps.increment(&2, &1))
      %{"a" => 3, "b" => 1, "c" => 1}
  """
  @spec increment(%{optional(key) => number()}, key, number()) :: %{optional(key) => number()} when key: any()
  def increment(map, key, by \\ 1) when is_non_struct_map(map) and is_number(by) do
    Map.update(map, key, by, &(&1 + by))
  end

  @doc """
  Gives a key of a map a new name, and keeps the other entries.

  If `old` is absent, this function returns the map with no change. If
  `new` is already a key of the map, the value of `old` would replace its
  value. Thus this function raises `ArgumentError` for that case. If `old`
  and `new` are equal, the map stays the same.

  `take_as/2` is different. It returns only the keys of its mapping.

  The map must be a plain map. For a struct, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.rename_key(%{mail: "ada@example.com", name: "Ada"}, :mail, :email)
      %{email: "ada@example.com", name: "Ada"}

      iex> Shoddy.Maps.rename_key(%{name: "Ada"}, :mail, :email)
      %{name: "Ada"}

      iex> Shoddy.Maps.rename_key(%{mail: "a@example.com", email: "b@example.com"}, :mail, :email)
      ** (ArgumentError) the new key :email is already in the map
  """
  @spec rename_key(map(), any(), any()) :: map()
  def rename_key(map, old, new) when is_non_struct_map(map) do
    cond do
      old === new or not is_map_key(map, old) -> map
      is_map_key(map, new) -> raise ArgumentError, "the new key #{inspect(new)} is already in the map"
      true -> map |> Map.delete(old) |> Map.put(new, Map.fetch!(map, old))
    end
  end

  @doc """
  Converts each key of a map into a string, at the top level only.

  The function converts each key with `to_string/1`. Thus an atom, a number
  and a string are correct keys. For other keys, `to_string/1` gives these
  results:

  - A charlist becomes a string, such as `~c"a"` to `"a"`.
  - Another list raises `ArgumentError`.
  - A tuple, or another value that does not implement `String.Chars`, raises
    `Protocol.UndefinedError`.

  If two keys give the same string, such as `:a` and `"a"`, this function
  raises `ArgumentError`, as `map_keys/2` does.

  The function does not change a nested map. The map must be a plain map.
  For a struct, it raises `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.stringify_keys(%{"role" => :admin, 1 => :one, name: "Ada"})
      %{"name" => "Ada", "role" => :admin, "1" => :one}

      iex> Shoddy.Maps.stringify_keys(%{"a" => 2, a: 1})
      ** (ArgumentError) more than one key has the same new key: "a" for the keys [:a, "a"]
  """
  @spec stringify_keys(%{optional(any()) => value}) :: %{optional(String.t()) => value} when value: any()
  def stringify_keys(map) when is_non_struct_map(map), do: map_keys(map, &to_string/1)

  @doc """
  Compares two maps, and returns the added, removed and changed entries.

  The result is a map with three maps:

    * `:added` - The entries of `new` with a key that `old` does not have.
    * `:removed` - The entries of `old` with a key that `new` does not have.
    * `:changed` - For each key that is in the two maps with different
      values, a tuple `{old_value, new_value}`.

  The function compares the values with the strict equality operator
  `===/2`, so `1` and `1.0` are different. It compares only the top level. A
  nested map that changes is one changed value.

  The two maps must be plain maps. For a struct, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.diff(%{name: "Ada", role: :user, age: 36}, %{name: "Ada", role: :admin, email: "ada@example.com"})
      %{added: %{email: "ada@example.com"}, removed: %{age: 36}, changed: %{role: {:user, :admin}}}

      iex> Shoddy.Maps.diff(%{a: 1}, %{a: 1})
      %{added: %{}, removed: %{}, changed: %{}}
  """
  @spec diff(map(), map()) :: %{added: map(), removed: map(), changed: map()}
  def diff(old, new) when is_non_struct_map(old) and is_non_struct_map(new) do
    changed =
      for {key, old_value} <- old,
          {:ok, new_value} <- [Map.fetch(new, key)],
          old_value !== new_value,
          into: %{},
          do: {key, {old_value, new_value}}

    %{added: Map.drop(new, Map.keys(old)), removed: Map.drop(old, Map.keys(new)), changed: changed}
  end

  @doc """
  Swaps the keys and the values of a map.

  Each value becomes a key, and its key becomes the value. If two keys have
  the same value, the result could keep only one of them. Thus this function
  raises `ArgumentError` for such values. The message tells each such value,
  in the order of terms.

  The map must be a plain map. For a struct, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Maps.invert(%{admin: 1, user: 2})
      %{1 => :admin, 2 => :user}

      iex> Shoddy.Maps.invert(%{a: 1, b: 1})
      ** (ArgumentError) more than one key has the same value: [1]
  """
  @spec invert(%{optional(key) => value}) :: %{optional(value) => key} when key: any(), value: any()
  def invert(map) when is_non_struct_map(map) do
    inverted = Map.new(map, fn {key, value} -> {value, key} end)

    if map_size(inverted) == map_size(map) do
      inverted
    else
      values = map |> Map.values() |> Shoddy.Lists.duplicates() |> Enum.sort()
      raise ArgumentError, "more than one key has the same value: #{inspect(values)}"
    end
  end

  defp put_when(struct, :__struct__, _value, _put?) when is_struct(struct) do
    raise KeyError,
      key: :__struct__,
      term: struct,
      message: "the key :__struct__ is not a field of the struct #{inspect(struct.__struct__)}"
  end

  defp put_when(struct, key, _value, _put?) when is_struct(struct) and not is_map_key(struct, key) do
    raise KeyError, key: key, term: struct
  end

  defp put_when(map, key, value, true), do: Map.put(map, key, value)
  defp put_when(map, _key, _value, false), do: map
end
