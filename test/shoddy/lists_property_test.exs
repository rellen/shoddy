defmodule Shoddy.ListsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Lists

  defp element, do: one_of([integer(0..5), member_of([:a, :b, :c]), float(min: 0.0, max: 2.0)])

  describe "duplicates/1" do
    property "returns each element that occurs more than one time, one time each, in the order of first occurrence" do
      check all(list <- list_of(element(), max_length: 20)) do
        expected = Enum.filter(Enum.uniq(list), fn x -> Enum.count(list, &(&1 === x)) > 1 end)

        assert Lists.duplicates(list) == expected
      end
    end
  end

  describe "duplicates_by/2" do
    property "returns the elements of each key that duplicates/1 returns for the keys" do
      check all(list <- list_of(tuple({element(), integer()}), max_length: 20)) do
        key = &elem(&1, 0)
        result = Lists.duplicates_by(list, key)
        expected_keys = list |> Enum.map(key) |> Lists.duplicates()

        assert MapSet.new(Map.keys(result)) == MapSet.new(expected_keys)

        for {k, elements} <- result do
          assert elements == Enum.filter(list, &(key.(&1) === k))
        end
      end
    end
  end

  describe "has_duplicates?/1" do
    property "returns true only if an element occurs more than one time" do
      check all(
              list <- list_of(element(), max_length: 20),
              at <- integer(0..20),
              unique_count <- integer(0..1_100)
            ) do
        {front, back} = Enum.split(list, at)
        full = front ++ Enum.map(1..unique_count//1, &{:unique, &1}) ++ back

        assert Lists.has_duplicates?(full) == (length(Enum.uniq(full)) != length(full))
      end
    end
  end
end
