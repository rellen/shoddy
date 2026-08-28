defmodule Quicksand.MapsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Quicksand.Maps

  # These generators give simple values on purpose. The function put_if/3
  # examines only whether a value is truthy, so a deep value gives no more
  # cover than a simple value, and it makes the test much slower.
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

    property "gives the same result as Map.put/3 for a truthy value" do
      check all(map <- any_map(), key <- simple(), value <- truthy()) do
        assert Maps.put_if(map, key, value) == Map.put(map, key, value)
      end
    end

    property "never removes an entry" do
      check all(map <- any_map(), key <- simple(), value <- simple()) do
        assert map_size(Maps.put_if(map, key, value)) >= map_size(map)
      end
    end

    property "gives one of two results only" do
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
end
