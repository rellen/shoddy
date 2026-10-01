defmodule Shoddy.MapsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Lists
  alias Shoddy.Maps

  defp simple, do: one_of([integer(), atom(:alphanumeric), string(:alphanumeric), boolean()])

  defp falsy, do: member_of([nil, false])

  defp truthy, do: filter(simple(), & &1)

  defp any_map, do: map_of(simple(), simple(), max_length: 10)

  describe "put_if/3" do
    property "returns the map with no change for a falsy value" do
      check all(map <- any_map(), key <- simple(), value <- falsy()) do
        assert Maps.put_if(map, key, value) == map
      end
    end

    property "puts a truthy value under the key" do
      check all(map <- any_map(), key <- simple(), value <- truthy()) do
        assert Map.get(Maps.put_if(map, key, value), key) == value
      end
    end

    property "returns the same result as Map.put/3 for a truthy value" do
      check all(map <- any_map(), key <- simple(), value <- truthy()) do
        assert Maps.put_if(map, key, value) == Map.put(map, key, value)
      end
    end

    property "never removes an entry" do
      check all(map <- any_map(), key <- simple(), value <- simple()) do
        assert map_size(Maps.put_if(map, key, value)) >= map_size(map)
      end
    end

    property "returns one of two results only" do
      check all(map <- any_map(), key <- simple(), value <- simple()) do
        result = Maps.put_if(map, key, value)
        assert result == map or result == Map.put(map, key, value)
      end
    end

    property "changes no other entry" do
      check all(map <- any_map(), key <- simple(), value <- simple()) do
        result = Maps.put_if(map, key, value)
        assert Map.delete(result, key) == Map.delete(map, key)
      end
    end
  end

  describe "put_present/3" do
    property "returns the map with no change for nil, and the result of Map.put/3 for other values" do
      check all(map <- any_map(), key <- simple(), value <- one_of([constant(nil), simple()])) do
        expected = if is_nil(value), do: map, else: Map.put(map, key, value)
        assert Maps.put_present(map, key, value) == expected
      end
    end
  end

  describe "get_present/3" do
    property "returns the default for an absent key or nil, and the value otherwise" do
      check all(map <- map_of(simple(), one_of([constant(nil), simple()]), max_length: 10), key <- simple()) do
        expected = if is_nil(Map.get(map, key)), do: :default, else: Map.fetch!(map, key)

        assert Maps.get_present(map, key, :default) === expected
      end
    end
  end

  describe "map_values/2" do
    property "keeps each key, and applies the function to its value" do
      check all(map <- any_map()) do
        result = Maps.map_values(map, fn value -> {value} end)

        assert Map.keys(result) == Map.keys(map)
        assert Enum.all?(map, fn {key, value} -> result[key] === {value} end)
      end
    end
  end

  describe "map_keys/2" do
    property "applies the function to each key, and raises only if two keys get the same new key" do
      check all(map <- map(list_of(tuple({integer(-5..5), simple()}), max_length: 10), &Map.new/1)) do
        new_key = &abs/1

        if Lists.has_duplicates?(Enum.map(Map.keys(map), new_key)) do
          assert_raise ArgumentError, fn -> Maps.map_keys(map, new_key) end
        else
          assert Maps.map_keys(map, new_key) == Map.new(map, fn {key, value} -> {abs(key), value} end)
        end
      end
    end
  end

  describe "put_path/3" do
    property "returns the result of a model that makes each absent or nil map, or raises for another value" do
      check all(
              map <-
                small_map(
                  tree(one_of([integer(0..2), constant(nil), list_of(integer(0..2), max_length: 1)]), &small_map/1)
                ),
              path <- list_of(member_of([:a, :b, :c]), min_length: 1, max_length: 4)
            ) do
        case model_put_path(map, path) do
          {:ok, expected} -> assert Maps.put_path(map, path, :new) == expected
          :not_a_map -> assert_raise ArgumentError, fn -> Maps.put_path(map, path, :new) end
        end
      end
    end
  end

  describe "fetch_keys/2" do
    property "returns the same map as Map.take/2 if each key is present, and the absent keys otherwise" do
      check all(map <- any_map(), keys <- list_of(simple(), max_length: 5)) do
        missing = keys |> Enum.reject(&Map.has_key?(map, &1)) |> Enum.uniq()
        expected = if missing == [], do: {:ok, Map.take(map, keys)}, else: {:error, {:missing_keys, missing}}

        assert Maps.fetch_keys(map, keys) == expected
      end
    end
  end

  describe "compact/1" do
    property "removes each nil value, and keeps each other entry" do
      check all(map <- map_of(simple(), one_of([constant(nil), simple()]), max_length: 10)) do
        assert Maps.compact(map) == for({key, value} <- map, not is_nil(value), into: %{}, do: {key, value})
      end
    end
  end

  describe "increment/3" do
    property "returns the same result as Map.update/4 with the amount as the initial value" do
      check all(
              map <- map(list_of(tuple({member_of([:a, :b]), integer()}), max_length: 2), &Map.new/1),
              key <- member_of([:a, :b, :c]),
              by <- integer()
            ) do
        assert Maps.increment(map, key, by) == Map.update(map, key, by, &(&1 + by))
      end
    end
  end

  describe "rename_key/3" do
    property "moves the value to the new key, or raises if the new key is taken" do
      check all(map <- any_map(), old <- simple(), new <- simple()) do
        cond do
          old === new or not Map.has_key?(map, old) ->
            assert Maps.rename_key(map, old, new) == map

          Map.has_key?(map, new) ->
            assert_raise ArgumentError, fn -> Maps.rename_key(map, old, new) end

          true ->
            result = Maps.rename_key(map, old, new)
            assert result[new] === map[old]
            assert Map.delete(result, new) == Map.delete(map, old)
        end
      end
    end
  end

  describe "stringify_keys/1" do
    property "returns the same result as map_keys/2 with to_string/1" do
      key = one_of([atom(:alphanumeric), integer(), string(:alphanumeric)])

      check all(map <- map_of(key, simple(), max_length: 8)) do
        if Lists.has_duplicates?(Enum.map(Map.keys(map), &to_string/1)) do
          assert_raise ArgumentError, fn -> Maps.stringify_keys(map) end
        else
          assert Maps.stringify_keys(map) == Map.new(map, fn {key, value} -> {to_string(key), value} end)
        end
      end
    end
  end

  describe "diff/2" do
    property "gives the parts that rebuild the new map from the old map" do
      check all(old <- any_map(), new <- any_map()) do
        %{added: added, removed: removed, changed: changed} = Maps.diff(old, new)

        rebuilt =
          old |> Map.drop(Map.keys(removed)) |> Map.merge(added) |> Map.merge(Maps.map_values(changed, &elem(&1, 1)))

        assert rebuilt == new

        assert Enum.all?(changed, fn {key, {before, after_}} ->
                 old[key] === before and new[key] === after_ and before !== after_
               end)
      end
    end
  end

  describe "invert/1" do
    property "returns a map that invert/1 changes back, or raises for a duplicate value" do
      check all(map <- map_of(integer(), integer(0..20), max_length: 8)) do
        if Lists.has_duplicates?(Map.values(map)) do
          assert_raise ArgumentError, fn -> Maps.invert(map) end
        else
          assert map |> Maps.invert() |> Maps.invert() == map
        end
      end
    end
  end

  describe "a struct as the first argument" do
    @fields URI.__struct__() |> Map.keys()

    for function <- [:put_if, :put_present] do
      property "#{function}/3 raises KeyError for each key that is not a field of the struct, for any value" do
        check all(
                key <- filter(simple(), &(&1 not in @fields)),
                value <- one_of([constant(nil), simple()])
              ) do
          assert_raise KeyError, fn -> apply(Maps, unquote(function), [%URI{}, key, value]) end
        end
      end
    end
  end

  describe "take_as/2" do
    property "returns the value of each key of the mapping that is in the map, under the new name" do
      check all(map <- any_map(), mapping <- map_of(simple(), integer())) do
        mapping = mapping |> Enum.uniq_by(&elem(&1, 1)) |> Map.new()

        expected =
          for {key, new_key} <- mapping, Map.has_key?(map, key), into: %{}, do: {new_key, map[key]}

        assert Maps.take_as(map, mapping) == expected
      end
    end
  end

  describe "deep_merge/2" do
    property "takes each value from the right map, and merges two plain maps of the same key" do
      check all(left <- nested_map(), right <- nested_map()) do
        assert_merged(left, right, Maps.deep_merge(left, right))
      end
    end
  end

  defp nested_map do
    leaf = one_of([integer(0..2), constant(nil), list_of(integer(0..2), max_length: 2), constant(~D[2024-01-01])])
    nested = tree(leaf, &small_map/1)

    small_map(nested)
  end

  defp small_map(values), do: map(list_of(tuple({member_of([:a, :b, :c]), values}), max_length: 4), &Map.new/1)

  defp assert_merged(left, right, result) do
    assert MapSet.new(Map.keys(result)) == MapSet.new(Map.keys(left) ++ Map.keys(right))

    for {key, value} <- result do
      case {Map.fetch(left, key), Map.fetch(right, key)} do
        {{:ok, l}, {:ok, r}} when is_non_struct_map(l) and is_non_struct_map(r) -> assert_merged(l, r, value)
        {_left, {:ok, r}} -> assert value === r
        {{:ok, l}, :error} -> assert value === l
      end
    end
  end

  defp model_put_path(map, [key]), do: {:ok, Map.put(map, key, :new)}

  defp model_put_path(map, [key | rest]) do
    case Map.get(map, key) do
      nil -> model_put_child(map, key, %{}, rest)
      child when is_map(child) -> model_put_child(map, key, child, rest)
      _other -> :not_a_map
    end
  end

  defp model_put_child(map, key, child, rest) do
    case model_put_path(child, rest) do
      {:ok, new_child} -> {:ok, Map.put(map, key, new_child)}
      :not_a_map -> :not_a_map
    end
  end
end
