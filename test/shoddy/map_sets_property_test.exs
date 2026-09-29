defmodule Shoddy.MapSetsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.MapSets

  defp element, do: one_of([integer(), atom(:alphanumeric), string(:alphanumeric), boolean()])

  defp any_map_set, do: map(list_of(element(), max_length: 10), &MapSet.new/1)

  defp elements, do: list_of(element(), max_length: 10)

  defp map_set_with_member do
    bind(list_of(element(), min_length: 1, max_length: 10), fn list ->
      bind(member_of(list), fn element -> constant({MapSet.new(list), element}) end)
    end)
  end

  describe "toggle/2" do
    property "deletes an element that is a member" do
      check all({map_set, element} <- map_set_with_member()) do
        result = MapSets.toggle(map_set, element)

        refute MapSet.member?(result, element)
        assert result == MapSet.delete(map_set, element)
        assert MapSet.size(result) == MapSet.size(map_set) - 1
      end
    end

    property "puts an element that is not a member into the map set" do
      check all(
              map_set <- any_map_set(),
              element <- element(),
              not MapSet.member?(map_set, element)
            ) do
        result = MapSets.toggle(map_set, element)

        assert MapSet.member?(result, element)
        assert result == MapSet.put(map_set, element)
        assert MapSet.size(result) == MapSet.size(map_set) + 1
      end
    end

    property "always changes the membership of the element" do
      check all(map_set <- any_map_set(), element <- element()) do
        result = MapSets.toggle(map_set, element)

        assert MapSet.member?(result, element) != MapSet.member?(map_set, element)
      end
    end

    property "changes no other element" do
      check all(map_set <- any_map_set(), element <- element()) do
        result = MapSets.toggle(map_set, element)

        assert MapSet.delete(result, element) == MapSet.delete(map_set, element)
      end
    end

    property "returns the initial map set after two calls" do
      check all(map_set <- any_map_set(), element <- element()) do
        assert map_set |> MapSets.toggle(element) |> MapSets.toggle(element) == map_set
      end
    end

    property "changes the size of the map set by one" do
      check all(map_set <- any_map_set(), element <- element()) do
        result = MapSets.toggle(map_set, element)

        assert abs(MapSet.size(result) - MapSet.size(map_set)) == 1
      end
    end

    property "treats a list as one element" do
      check all(map_set <- any_map_set(), list <- elements()) do
        result = MapSets.toggle(map_set, list)

        assert MapSet.member?(result, list) != MapSet.member?(map_set, list)
        assert abs(MapSet.size(result) - MapSet.size(map_set)) == 1
      end
    end
  end

  describe "toggle_all/2" do
    property "returns the same result as one call to toggle/2 for each element" do
      check all(map_set <- any_map_set(), list <- elements()) do
        expected = Enum.reduce(list, map_set, fn element, acc -> MapSets.toggle(acc, element) end)

        assert MapSets.toggle_all(map_set, list) == expected
      end
    end

    property "returns the map set with no change for an empty list" do
      check all(map_set <- any_map_set()) do
        assert MapSets.toggle_all(map_set, []) == map_set
      end
    end

    property "changes the membership of an element that occurs an odd number of times" do
      check all(map_set <- any_map_set(), list <- elements(), element <- element()) do
        result = MapSets.toggle_all(map_set, list)
        odd? = rem(Enum.count(list, &(&1 === element)), 2) == 1

        assert MapSet.member?(result, element) == (MapSet.member?(map_set, element) != odd?)
      end
    end

    property "changes no element that the list does not contain" do
      check all(map_set <- any_map_set(), list <- elements()) do
        result = MapSets.toggle_all(map_set, list)
        touched = MapSet.new(list)

        assert MapSet.difference(result, touched) == MapSet.difference(map_set, touched)
      end
    end

    property "returns the initial map set after two calls with the same list" do
      check all(map_set <- any_map_set(), list <- elements()) do
        assert map_set |> MapSets.toggle_all(list) |> MapSets.toggle_all(list) == map_set
      end
    end

    property "ignores the order of the elements of the list" do
      check all(map_set <- any_map_set(), list <- elements()) do
        assert MapSets.toggle_all(map_set, list) ==
                 MapSets.toggle_all(map_set, Enum.reverse(list))
      end
    end

    property "returns the same result as toggle/2 for a list of one element" do
      check all(map_set <- any_map_set(), element <- element()) do
        assert MapSets.toggle_all(map_set, [element]) == MapSets.toggle(map_set, element)
      end
    end
  end
end
