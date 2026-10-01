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
