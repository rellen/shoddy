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
end
