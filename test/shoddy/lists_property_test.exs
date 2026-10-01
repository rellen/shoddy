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

  describe "index_by/2" do
    property "returns the element of each key if the keys are unique, and raises otherwise" do
      check all(list <- list_of(tuple({element(), integer()}), max_length: 20)) do
        key = &elem(&1, 0)

        if Lists.has_duplicates?(Enum.map(list, key)) do
          assert_raise ArgumentError, fn -> Lists.index_by(list, key) end
        else
          index = Lists.index_by(list, key)

          assert map_size(index) == length(list)
          assert Enum.all?(list, &(index[key.(&1)] === &1))
        end
      end
    end
  end

  describe "group_by_in_order/2" do
    property "has the same groups as Enum.group_by/2, in the order of first occurrence" do
      check all(list <- list_of(tuple({element(), integer()}), max_length: 20)) do
        key = &elem(&1, 0)
        result = Lists.group_by_in_order(list, key)

        assert Map.new(result) == Enum.group_by(list, key)
        assert Enum.map(result, &elem(&1, 0)) == list |> Enum.map(key) |> Enum.uniq()
      end
    end
  end

  describe "upsert_by/4" do
    property "replaces the first element with the same key, or adds the element at the end" do
      check all(list <- list_of(tuple({element(), integer()}), max_length: 10), new <- tuple({element(), integer()})) do
        key = &elem(&1, 0)

        expected =
          case Enum.find_index(list, &(key.(&1) === key.(new))) do
            nil -> list ++ [new]
            index -> List.replace_at(list, index, new)
          end

        assert Lists.upsert_by(list, key, new) == expected
      end
    end
  end

  describe "sort_by_keys/2" do
    property "returns the same order as a stable sort by the last key and then by the first key" do
      check all(list <- list_of(tuple({integer(0..3), integer(0..3), integer()}), max_length: 20)) do
        expected = list |> Enum.sort_by(&elem(&1, 1), :asc) |> Enum.sort_by(&elem(&1, 0), :desc)

        assert Lists.sort_by_keys(list, [{:desc, &elem(&1, 0)}, {:asc, &elem(&1, 1)}]) == expected
      end
    end
  end

  describe "toggle/2" do
    property "removes each occurrence of a member, and adds a non-member at the end" do
      check all(list <- list_of(element(), max_length: 10), x <- element()) do
        expected = if x in list, do: Enum.reject(list, &(&1 === x)), else: list ++ [x]

        assert Lists.toggle(list, x) == expected
      end
    end
  end

  describe "move/3" do
    property "keeps the elements, and puts the moved element at the new index" do
      check all(
              list <- list_of(element(), min_length: 1, max_length: 10),
              from <- integer(0..9),
              to <- integer(0..9)
            ) do
        count = length(list)

        if from < count and to < count do
          result = Lists.move(list, from, to)

          assert Enum.at(result, to) === Enum.at(list, from)
          assert List.delete_at(result, to) == List.delete_at(list, from)
        else
          assert_raise ArgumentError, fn -> Lists.move(list, from, to) end
        end
      end
    end
  end

  describe "sorted?/2" do
    property "returns the same answer as a comparison with Enum.sort/2" do
      check all(list <- list_of(integer(0..5), max_length: 10), sorter <- member_of([:asc, :desc])) do
        assert Lists.sorted?(list, sorter) == (Enum.sort(list, sorter) == list)
      end
    end
  end

  describe "cycle_next/2" do
    property "steps through the list in order, and returns to the first element" do
      check all(list <- uniq_list_of(integer(), min_length: 1, max_length: 8)) do
        cycle = hd(list) |> Stream.iterate(&Lists.cycle_next(list, &1)) |> Enum.take(length(list) + 1)

        assert Enum.drop(cycle, -1) == list
        assert List.last(cycle) == hd(list)
      end
    end
  end

  describe "all_same_by?/2" do
    property "returns true only if the keys have at most one value" do
      check all(list <- list_of(tuple({element(), integer()}), max_length: 10)) do
        keys = list |> MapSet.new(&elem(&1, 0))

        assert Lists.all_same_by?(list, &elem(&1, 0)) == MapSet.size(keys) <= 1
      end
    end
  end

  describe "join_by/4" do
    property "puts each left element with the right element of its key, or nil" do
      check all(
              left <- list_of(integer(0..5), max_length: 10),
              right <- map(list_of(integer(0..7), max_length: 8), &Enum.uniq/1)
            ) do
        assert Lists.join_by(left, right, & &1, & &1) == Enum.map(left, &{&1, if(&1 in right, do: &1)})
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

  describe "single/1" do
    property "returns the element for one element, and an error with the number of elements otherwise" do
      check all(list <- list_of(element(), max_length: 20)) do
        expected =
          case length(list) do
            0 -> {:error, :empty}
            1 -> {:ok, hd(list)}
            count -> {:error, {:many, count}}
          end

        assert Lists.single(list) === expected
      end
    end
  end
end
