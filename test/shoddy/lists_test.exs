defmodule Shoddy.ListsTest do
  use ExUnit.Case, async: true

  import Shoddy.Lists

  doctest Shoddy.Lists

  describe "duplicates/1" do
    test "returns each repeated element one time" do
      assert duplicates([:a, :a, :a, :a]) == [:a]
    end

    test "returns the elements in the order of their first occurrence" do
      assert duplicates([:c, :b, :a, :a, :b, :c]) == [:c, :b, :a]
    end

    test "returns an empty list if each element occurs one time" do
      assert duplicates([1, 2, 3]) == []
    end

    test "compares with the strict equality operator" do
      assert duplicates([1, 1.0]) == []
      assert duplicates([1.0, 1.0]) == [1.0]
    end

    test "accepts elements of any type" do
      assert duplicates([%{a: 1}, [1], %{a: 1}, [1], nil, nil]) == [%{a: 1}, [1], nil]
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&duplicates/1, [MapSet.new([1])]) end
    end
  end

  describe "duplicates_by/2" do
    test "returns each element of a shared key, in the order of the input" do
      assert duplicates_by([{:b, 1}, {:a, 2}, {:b, 3}, {:a, 4}, {:c, 5}], &elem(&1, 0)) ==
               %{a: [{:a, 2}, {:a, 4}], b: [{:b, 1}, {:b, 3}]}
    end

    test "returns each element of a key that occurs three times" do
      assert duplicates_by([1, 2, 4, 7], &rem(&1, 3)) == %{1 => [1, 4, 7]}
    end

    test "returns an empty map for an empty list" do
      assert duplicates_by([], & &1) == %{}
    end

    test "accepts nil and false as keys" do
      assert duplicates_by([1, 2, 3], fn _ -> nil end) == %{nil => [1, 2, 3]}
      assert duplicates_by([1, 2], fn _ -> false end) == %{false => [1, 2]}
    end

    test "compares the keys with the strict equality operator" do
      assert duplicates_by([1, 1.0], & &1) == %{}
      assert duplicates_by([1.0, 1.0], & &1) == %{1.0 => [1.0, 1.0]}
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&duplicates_by/2, [MapSet.new([1]), & &1]) end
    end

    test "raises FunctionClauseError for a key function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> apply(&duplicates_by/2, [[1], fn -> 1 end]) end
    end
  end

  describe "index_by/2" do
    test "returns a map from the key of each element to the element" do
      assert index_by([{:a, 1}, {:b, 2}], &elem(&1, 0)) == %{a: {:a, 1}, b: {:b, 2}}
    end

    test "accepts nil and false as keys" do
      assert index_by([1, 2], &if(&1 != 1, do: false)) == %{nil => 1, false => 2}
    end

    test "keeps 1 and 1.0 as two keys" do
      assert index_by([1, 1.0], & &1) == %{1 => 1, 1.0 => 1.0}
    end

    test "raises ArgumentError that tells each duplicate key, in the order of first occurrence" do
      assert_raise ArgumentError, "more than one element has the same key: [:b, :a]", fn ->
        index_by([{:b, 1}, {:a, 2}, {:b, 3}, {:a, 4}, {:a, 5}, {:c, 6}], &elem(&1, 0))
      end
    end

    test "raises ArgumentError for two equal elements" do
      assert_raise ArgumentError, fn -> index_by([:x, :x], & &1) end
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&index_by/2, [%{a: 1}, & &1]) end
    end

    test "raises FunctionClauseError for a key function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> apply(&index_by/2, [[1], fn -> 1 end]) end
    end
  end

  describe "index_by/3" do
    test "puts the return value of :value into the map" do
      assert index_by([{:a, 1}, {:b, 2}], &elem(&1, 0), value: &elem(&1, 1)) == %{a: 1, b: 2}
      assert index_by([{:a, nil}], &elem(&1, 0), value: &elem(&1, 1)) == %{a: nil}
    end

    test "keeps the first element of a key with on_duplicate: :first" do
      list = [{:a, 1}, {:b, 2}, {:a, 3}]
      assert index_by(list, &elem(&1, 0), on_duplicate: :first) == %{a: {:a, 1}, b: {:b, 2}}
    end

    test "keeps the last element of a key with on_duplicate: :last" do
      list = [{:a, 1}, {:b, 2}, {:a, 3}]
      assert index_by(list, &elem(&1, 0), on_duplicate: :last) == %{a: {:a, 3}, b: {:b, 2}}
    end

    test "raises ArgumentError for a duplicate key with on_duplicate: :raise, also with :value" do
      for opts <- [[on_duplicate: :raise], [on_duplicate: :raise, value: &elem(&1, 1)], [value: &elem(&1, 1)]] do
        assert_raise ArgumentError, "more than one element has the same key: [:a]", fn ->
          index_by([{:a, 1}, {:a, 1}], &elem(&1, 0), opts)
        end
      end
    end

    test "uses the two options together" do
      list = [{:a, 1}, {:a, 2}]
      assert index_by(list, &elem(&1, 0), value: &elem(&1, 1), on_duplicate: :first) == %{a: 1}
      assert index_by(list, &elem(&1, 0), value: &elem(&1, 1), on_duplicate: :last) == %{a: 2}
    end

    test "calls the two functions one time for each element, also for an element that it drops" do
      parent = self()

      tell = fn tag ->
        fn element ->
          send(parent, {tag, element})
          element
        end
      end

      index_by([1, 1], tell.(:key), value: tell.(:value), on_duplicate: :first)

      for tag <- [:key, :value] do
        assert_received {^tag, 1}
        assert_received {^tag, 1}
        refute_received {^tag, _element}
      end
    end

    test "raises ArgumentError for a wrong option, also for an empty list" do
      assert_raise ArgumentError, ~r/invalid value for :on_duplicate option: expected :raise, :first or :last/, fn ->
        index_by([], & &1, on_duplicate: :skip)
      end

      for value <- [nil, :name, fn -> 1 end, fn _a, _b -> 1 end] do
        assert_raise ArgumentError, ~r/invalid value for :value option: expected a function of arity 1/, fn ->
          index_by([], & &1, value: value)
        end
      end

      assert_raise ArgumentError, fn -> index_by([], & &1, on_duplicates: :first) end
    end

    test "raises FunctionClauseError for options that are not a list" do
      error = assert_raise FunctionClauseError, fn -> apply(&index_by/3, [[1], & &1, :first]) end
      assert {error.module, error.function} == {Shoddy.Lists, :index_by}
    end
  end

  describe "group_by_in_order/2" do
    test "keeps the order of the first element of each key and the order of the elements" do
      assert group_by_in_order([3, 1, 4, 1, 5, 9, 2, 6], &rem(&1, 3)) == [{0, [3, 9, 6]}, {1, [1, 4, 1]}, {2, [5, 2]}]
    end

    test "accepts nil and false as keys" do
      assert group_by_in_order([1, 2, 3], &if(&1 != 2, do: false)) == [{false, [1, 3]}, {nil, [2]}]
    end

    test "keeps 1 and 1.0 as two keys" do
      assert group_by_in_order([1, 1.0], & &1) == [{1, [1]}, {1.0, [1.0]}]
    end

    test "keeps the order for more than 32 keys" do
      keys = Enum.to_list(100..1//-1)

      assert group_by_in_order(keys, & &1) |> Enum.map(&elem(&1, 0)) == keys
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&group_by_in_order/2, [%{a: 1}, & &1]) end
    end
  end

  describe "upsert_by/4" do
    test "replaces only the first element with the same key, at its position" do
      assert upsert_by([{:a, 1}, {:b, 2}, {:a, 3}], &elem(&1, 0), {:a, 9}) == [{:a, 9}, {:b, 2}, {:a, 3}]
    end

    test "adds a new element at the end, or at the start with at: :start" do
      assert upsert_by([{:a, 1}], &elem(&1, 0), {:b, 2}) == [{:a, 1}, {:b, 2}]
      assert upsert_by([{:a, 1}], &elem(&1, 0), {:b, 2}, at: :start) == [{:b, 2}, {:a, 1}]
      assert upsert_by([], &elem(&1, 0), {:b, 2}) == [{:b, 2}]
    end

    test "ignores the option :at for a replacement" do
      assert upsert_by([{:a, 1}, {:b, 2}], &elem(&1, 0), {:b, 3}, at: :start) == [{:a, 1}, {:b, 3}]
    end

    test "compares the keys with the strict equality operator" do
      assert upsert_by([1], & &1, 1.0) == [1, 1.0]
    end

    test "raises ArgumentError for an unknown option or another value of :at" do
      assert_raise ArgumentError, fn -> upsert_by([], & &1, 1, position: :end) end
      assert_raise ArgumentError, ~r/expected :end or :start/, fn -> upsert_by([], & &1, 1, at: :middle) end
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&upsert_by/3, [%{}, & &1, 1]) end
    end
  end

  describe "sort_by_keys/2" do
    test "compares by the next key only if the values of the earlier key are equal" do
      list = [{2, :b}, {1, :b}, {2, :a}, {1, :a}]

      assert sort_by_keys(list, [&elem(&1, 0), &elem(&1, 1)]) == [{1, :a}, {1, :b}, {2, :a}, {2, :b}]
      assert sort_by_keys(list, [{:desc, &elem(&1, 0)}, {:asc, &elem(&1, 1)}]) == [{2, :a}, {2, :b}, {1, :a}, {1, :b}]
      assert sort_by_keys(list, [{:asc, &elem(&1, 1)}, {:desc, &elem(&1, 0)}]) == [{2, :a}, {1, :a}, {2, :b}, {1, :b}]
    end

    test "keeps the order of the input for equal values" do
      assert sort_by_keys([{1, :x}, {0, :y}, {1, :z}], [&elem(&1, 0)]) == [{0, :y}, {1, :x}, {1, :z}]
      assert sort_by_keys([{1, :x}, {0, :y}, {1, :z}], [{:desc, &elem(&1, 0)}]) == [{1, :x}, {1, :z}, {0, :y}]
    end

    test "uses compare/2 of a module" do
      times = [~U[2024-01-02 00:00:00Z], ~U[2023-12-31 00:00:00Z], ~U[2024-01-01 00:00:00Z]]

      assert sort_by_keys(times, [{:asc, & &1, DateTime}]) ==
               [~U[2023-12-31 00:00:00Z], ~U[2024-01-01 00:00:00Z], ~U[2024-01-02 00:00:00Z]]

      assert sort_by_keys(times, [{:desc, & &1, DateTime}]) ==
               [~U[2024-01-02 00:00:00Z], ~U[2024-01-01 00:00:00Z], ~U[2023-12-31 00:00:00Z]]
    end

    test "returns an empty list for an empty list" do
      assert sort_by_keys([], [& &1]) == []
    end

    test "raises ArgumentError for a key in a wrong form" do
      assert_raise ArgumentError, ~r/invalid key/, fn -> sort_by_keys([1], [:asc]) end
      assert_raise ArgumentError, ~r/invalid key/, fn -> sort_by_keys([1], [{:up, & &1}]) end
      assert_raise ArgumentError, ~r/invalid key/, fn -> sort_by_keys([1], [fn _a, _b -> true end]) end
      assert_raise ArgumentError, ~r/invalid key/, fn -> sort_by_keys([1], [{:up, & &1, Date}]) end
      assert_raise ArgumentError, ~r/invalid key/, fn -> sort_by_keys([1], [{:asc, :value, Date}]) end
      assert_raise ArgumentError, ~r/invalid key/, fn -> sort_by_keys([1], [{:asc, & &1, "Date"}]) end
    end

    test "raises ArgumentError for a module that does not export compare/2" do
      assert_raise ArgumentError, ~r/does not export compare\/2/, fn -> sort_by_keys([1], [{:asc, & &1, Enum}]) end

      assert_raise ArgumentError, ~r/does not export compare\/2/, fn ->
        sort_by_keys([1], [{:asc, & &1, NoSuchModule}])
      end
    end

    test "raises FunctionClauseError for an empty list of keys" do
      assert_raise FunctionClauseError, fn -> apply(&sort_by_keys/2, [[1], []]) end
    end
  end

  describe "compare_by_keys/3" do
    test "compares by the next key only if the values of the earlier key are equal" do
      keys = [&elem(&1, 0), &elem(&1, 1)]

      assert compare_by_keys({1, :b}, {2, :a}, keys) == :lt
      assert compare_by_keys({2, :a}, {1, :b}, keys) == :gt
      assert compare_by_keys({1, :a}, {1, :b}, keys) == :lt
      assert compare_by_keys({1, :b}, {1, :a}, keys) == :gt
      assert compare_by_keys({1, :a}, {1, :a}, keys) == :eq
    end

    test "gives :lt for the larger value of a key with the direction :desc" do
      assert compare_by_keys(2, 1, [{:desc, & &1}]) == :lt
      assert compare_by_keys(1, 2, [{:desc, & &1}]) == :gt
      assert compare_by_keys(1, 1, [{:desc, & &1}]) == :eq
      assert compare_by_keys({1, :a}, {1, :b}, [{:asc, &elem(&1, 0)}, {:desc, &elem(&1, 1)}]) == :gt
    end

    test "uses compare/2 of a module, where the operator < gives a wrong answer" do
      earlier = {1, ~U[2026-09-30 10:00:00Z]}
      later = {1, ~U[2026-10-01 10:00:00Z]}
      keys = [&elem(&1, 0), {:asc, &elem(&1, 1), DateTime}]

      # The operator < compares the day before the month, so it gives the wrong order.
      refute apply(&</2, [earlier, later])
      assert compare_by_keys(earlier, later, keys) == :lt
      assert compare_by_keys(later, earlier, keys) == :gt
      assert compare_by_keys(later, earlier, [&elem(&1, 0), {:desc, &elem(&1, 1), DateTime}]) == :lt
    end

    test "agrees with sort_by_keys/2 for each pair of a list" do
      list = for a <- 1..3, b <- [:x, :y], c <- 1..2, do: {a, b, c}
      keys = [{:desc, &elem(&1, 0)}, &elem(&1, 1), {:desc, &elem(&1, 2)}]
      sorted = sort_by_keys(Enum.shuffle(list), keys)

      for {first, i} <- Enum.with_index(sorted), {second, j} <- Enum.with_index(sorted) do
        expected = if i < j, do: :lt, else: if(i > j, do: :gt, else: :eq)
        assert compare_by_keys(first, second, keys) == expected
      end
    end

    test "raises ArgumentError for a key in a wrong form" do
      assert_raise ArgumentError, ~r/invalid key/, fn -> compare_by_keys(1, 2, [:asc]) end
      assert_raise ArgumentError, ~r/invalid key/, fn -> compare_by_keys(1, 2, [{:up, & &1}]) end
    end

    test "raises ArgumentError for a module that does not export compare/2" do
      assert_raise ArgumentError, ~r/does not export compare\/2/, fn -> compare_by_keys(1, 2, [{:asc, & &1, Enum}]) end
    end

    test "raises FunctionClauseError for an empty list of keys" do
      assert_raise FunctionClauseError, fn -> apply(&compare_by_keys/3, [1, 2, []]) end
    end
  end

  describe "toggle/2" do
    test "removes each occurrence, and keeps the order of the others" do
      assert toggle([:a, :b, :a, :c], :a) == [:b, :c]
    end

    test "adds an absent element at the end" do
      assert toggle([], :a) == [:a]
      assert toggle([1], 1.0) == [1, 1.0]
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&toggle/2, [MapSet.new([1]), 1]) end
    end
  end

  describe "move/3" do
    test "moves an element forward, backward and to the same place" do
      assert move([:a, :b, :c], 0, 2) == [:b, :c, :a]
      assert move([:a, :b, :c], 2, 0) == [:c, :a, :b]
      assert move([:a, :b, :c], 1, 1) == [:a, :b, :c]
    end

    test "raises ArgumentError for an index that is not in the list" do
      assert_raise ArgumentError, "the index 3 is not in a list of 3 elements", fn -> move([:a, :b, :c], 3, 0) end
      assert_raise ArgumentError, "the index 0 is not in a list of 0 elements", fn -> move([], 0, 0) end
    end

    test "raises FunctionClauseError from move/3 itself for a negative index or a value that is not a list" do
      for args <- [[[:a], -1, 0], [[:a], 0, -1], [%{}, 0, 0], [[:a], 0.0, 0]] do
        error = assert_raise FunctionClauseError, fn -> apply(&move/3, args) end
        assert {error.module, error.function} == {Shoddy.Lists, :move}
      end
    end
  end

  describe "sorted?/2" do
    test "accepts equal neighbours in each direction" do
      assert sorted?([1, 1, 2])
      assert sorted?([2, 1, 1], :desc)
      refute sorted?([1, 2], :desc)
    end

    test "uses compare/2 of a module" do
      refute sorted?([~D[2024-02-01], ~D[2024-01-31]], {:asc, Date})
      assert sorted?([~D[2024-02-01], ~D[2024-01-31]], {:desc, Date})
    end

    test "accepts a module alone as the sorter {:asc, module}, as Enum.sort/2 does" do
      assert sorted?([~D[2024-01-31], ~D[2024-02-01]], Date)
      refute sorted?([~D[2024-02-01], ~D[2024-01-31]], Date)
    end

    test "accepts a function of arity 2" do
      assert sorted?(["bb", "a", "ccc"], &(byte_size(&1) <= byte_size(&2))) == false
      assert sorted?(["a", "bb", "ccc"], &(byte_size(&1) <= byte_size(&2)))
    end

    test "stops at the first pair in the wrong order" do
      refute sorted?([2, 1, :never_compared], fn a, b -> if is_atom(b), do: raise("read"), else: a <= b end)
    end

    test "raises ArgumentError for a sorter in another form or a module without compare/2" do
      assert_raise ArgumentError, ~r/the module :up does not export compare\/2/, fn -> sorted?([1], :up) end
      assert_raise ArgumentError, ~r/invalid sorter/, fn -> sorted?([1], "asc") end
      assert_raise ArgumentError, ~r/invalid sorter/, fn -> sorted?([1], {:up, Date}) end
      assert_raise ArgumentError, ~r/does not export compare\/2/, fn -> sorted?([1], {:asc, Enum}) end
    end
  end

  describe "cycle_next/2" do
    test "uses the first occurrence of the current element" do
      assert cycle_next([:a, :b, :a, :c], :a) == :b
    end

    test "compares with the strict equality operator" do
      assert_raise ArgumentError, "the element 1.0 is not in the list", fn -> cycle_next([1, 2], 1.0) end
    end

    test "raises FunctionClauseError for an empty list" do
      assert_raise FunctionClauseError, fn -> apply(&cycle_next/2, [[], :a]) end
    end
  end

  describe "all_same_by?/2" do
    test "returns true for one element" do
      assert all_same_by?([:a], & &1)
    end

    test "compares the keys with the strict equality operator" do
      refute all_same_by?([1, 1.0], & &1)
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&all_same_by?/2, [%{a: 1}, & &1]) end
    end
  end

  describe "join_by/4" do
    test "keeps the order of the left list and a left key that occurs more than one time" do
      assert join_by([2, 1, 2], [1, 2], & &1, & &1) == [{2, 2}, {1, 1}, {2, 2}]
    end

    test "returns nil for no partner, and ignores an element of the right list with no partner" do
      assert join_by([1], [2, 3], & &1, & &1) == [{1, nil}]
      assert join_by([], [1], & &1, & &1) == []
    end

    test "raises ArgumentError for a key of the right list that is not unique" do
      assert_raise ArgumentError, "more than one element has the same key: [1]", fn ->
        join_by([1], [1, 1], & &1, & &1)
      end
    end

    test "never matches a nil key, and accepts more than one nil key in the right list" do
      orders = [%{id: 10, user_id: nil}]
      users = [%{id: nil, name: "draft"}, %{id: nil, name: "new"}]

      assert join_by(orders, users, & &1.user_id, & &1.id) == [{%{id: 10, user_id: nil}, nil}]
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&join_by/4, [%{}, [], & &1, & &1]) end
    end
  end

  describe "group_join_by/4" do
    test "puts each left element with each right element of its key, in the order of the two lists" do
      left = [{:b}, {:a}, {:c}]
      right = [{:a, 1}, {:b, 2}, {:a, 3}, {:z, 4}]

      assert group_join_by(left, right, &elem(&1, 0), &elem(&1, 0)) ==
               [{{:b}, [{:b, 2}]}, {{:a}, [{:a, 1}, {:a, 3}]}, {{:c}, []}]
    end

    test "gives the same group to each left element with the same key" do
      assert group_join_by([1, 1], [1], & &1, & &1) == [{1, [1]}, {1, [1]}]
    end

    test "never matches a nil key" do
      assert group_join_by([%{k: nil}], [%{k: nil}, %{k: nil}], & &1.k, & &1.k) == [{%{k: nil}, []}]
    end

    test "matches the key false" do
      assert group_join_by([false], [false, true], & &1, & &1) == [{false, [false]}]
    end

    test "compares the keys with the strict equality operator" do
      assert group_join_by([1], [1.0], & &1, & &1) == [{1, []}]
    end

    test "returns an empty list for an empty left list, and empty groups for an empty right list" do
      assert group_join_by([], [1], & &1, & &1) == []
      assert group_join_by([1], [], & &1, & &1) == [{1, []}]
    end

    test "calls each key function one time for each element" do
      parent = self()

      key = fn element ->
        send(parent, {:key, element})
        element
      end

      group_join_by([:l], [:r], key, key)

      assert_received {:key, :l}
      assert_received {:key, :r}
      refute_received {:key, _element}
    end

    test "raises FunctionClauseError for an argument of the wrong type" do
      for args <- [[%{}, [], & &1, & &1], [[], :right, & &1, & &1], [[], [], nil, & &1], [[], [], & &1, &{&1, &2}]] do
        error = assert_raise FunctionClauseError, fn -> apply(&group_join_by/4, args) end
        assert {error.module, error.function} == {Shoddy.Lists, :group_join_by}
      end
    end
  end

  describe "has_duplicates?/1" do
    test "returns true for a duplicate at the start of a long list" do
      assert has_duplicates?([1, 1 | Enum.to_list(2..5_000)])
    end

    test "returns true for a duplicate after the first 1024 elements" do
      assert has_duplicates?(Enum.to_list(1..5_000) ++ [5_000])
    end

    test "returns true for an element in the first 1024 elements that occurs again after them" do
      assert has_duplicates?(Enum.to_list(1..5_000) ++ [1])
    end

    test "returns false for a long list with no duplicates" do
      refute has_duplicates?(Enum.to_list(1..5_000))
    end

    test "returns false for a list of 1024 different elements" do
      refute has_duplicates?(Enum.to_list(1..1_024))
    end

    test "compares with the strict equality operator" do
      refute has_duplicates?([1, 1.0])
      assert has_duplicates?([1.0, 1.0])
      refute has_duplicates?(Enum.to_list(1..2_000) ++ [1.0])
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&has_duplicates?/1, [MapSet.new([1])]) end
    end
  end

  describe "single/1" do
    test "returns the only element in an ok tuple" do
      assert single([%{id: 1}]) == {:ok, %{id: 1}}
    end

    test "returns an ok tuple for a falsy element" do
      assert single([nil]) == {:ok, nil}
      assert single([false]) == {:ok, false}
    end

    test "returns an ok tuple for an element that is a list" do
      assert single([[]]) == {:ok, []}
      assert single([[1, 2]]) == {:ok, [1, 2]}
    end

    test "returns :empty for an empty list" do
      assert single([]) == {:error, :empty}
    end

    test "returns the number of elements for more than one element" do
      assert single([1, 1]) == {:error, {:many, 2}}
      assert single(Enum.to_list(1..1_000)) == {:error, {:many, 1_000}}
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&single/1, [MapSet.new([1])]) end
      assert_raise FunctionClauseError, fn -> apply(&single/1, [nil]) end
    end
  end
end
