defmodule Shoddy.MapsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

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
end
