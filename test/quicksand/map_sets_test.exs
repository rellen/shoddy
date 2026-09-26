defmodule Quicksand.MapSetsTest do
  use ExUnit.Case, async: true

  import Quicksand.MapSets

  doctest Quicksand.MapSets

  # Some tests below call a function through apply/2. The compiler examines
  # the type of each argument at a direct call. It reports a type violation
  # for an argument that no clause of the function accepts. Those tests must
  # pass such an argument, because they examine the behaviour at run time.
  # The compiler does not examine the arguments of apply/2.

  describe "toggle/2" do
    test "puts an element that is not a member into the map set" do
      assert toggle(MapSet.new([:a, :b]), :c) == MapSet.new([:a, :b, :c])
    end

    test "puts an element into an empty map set" do
      assert toggle(MapSet.new(), :a) == MapSet.new([:a])
    end

    test "deletes an element that is a member" do
      assert toggle(MapSet.new([:a, :b]), :a) == MapSet.new([:b])
    end

    test "returns an empty map set if it deletes the only element" do
      assert toggle(MapSet.new([:a]), :a) == MapSet.new()
    end

    test "changes no other element" do
      assert toggle(MapSet.new([:a, :b, :c]), :b) == MapSet.new([:a, :c])
    end

    test "returns the initial map set after two calls with the same element" do
      set = MapSet.new([:a, :b])

      assert set |> toggle(:c) |> toggle(:c) == set
      assert set |> toggle(:a) |> toggle(:a) == set
    end

    test "accepts an element of any type" do
      assert toggle(MapSet.new(), "name") == MapSet.new(["name"])
      assert toggle(MapSet.new(), {:composite, 1}) == MapSet.new([{:composite, 1}])
      assert toggle(MapSet.new([%{a: 1}]), %{a: 1}) == MapSet.new()
    end

    test "treats a list as one element" do
      assert toggle(MapSet.new(), [1, 2]) == MapSet.new([[1, 2]])
      assert toggle(MapSet.new([[1, 2]]), [1, 2]) == MapSet.new()
      assert toggle(MapSet.new(), []) == MapSet.new([[]])
    end

    test "puts nil and false, because it examines membership only" do
      assert toggle(MapSet.new(), nil) == MapSet.new([nil])
      assert toggle(MapSet.new(), false) == MapSet.new([false])
      assert toggle(MapSet.new([nil]), nil) == MapSet.new()
    end

    test "compares an element with the strict equality operator" do
      assert toggle(MapSet.new([1]), 1.0) == MapSet.new([1, 1.0])
      assert toggle(MapSet.new([1.0]), 1.0) == MapSet.new()
    end

    test "raises FunctionClauseError for a first argument that is not a map set" do
      assert_raise FunctionClauseError, fn -> apply(&toggle/2, [[:a], :b]) end
      assert_raise FunctionClauseError, fn -> apply(&toggle/2, [%{a: 1}, :b]) end
      assert_raise FunctionClauseError, fn -> apply(&toggle/2, [nil, :b]) end
    end
  end

  describe "toggle_all/2" do
    test "puts each element that is not a member into the map set" do
      assert toggle_all(MapSet.new(), [:a, :b]) == MapSet.new([:a, :b])
    end

    test "deletes each element that is a member" do
      assert toggle_all(MapSet.new([:a, :b, :c]), [:a, :c]) == MapSet.new([:b])
    end

    test "deletes the members and puts the other elements in one call" do
      assert toggle_all(MapSet.new([:a, :b]), [:b, :c]) == MapSet.new([:a, :c])
    end

    test "returns the map set with no change for an empty list" do
      assert toggle_all(MapSet.new([:a, :b]), []) == MapSet.new([:a, :b])
      assert toggle_all(MapSet.new(), []) == MapSet.new()
    end

    test "toggles an element one time for each occurrence in the list" do
      assert toggle_all(MapSet.new(), [:a, :a]) == MapSet.new()
      assert toggle_all(MapSet.new(), [:a, :a, :a]) == MapSet.new([:a])
      assert toggle_all(MapSet.new([:a]), [:a, :a]) == MapSet.new([:a])
    end

    test "returns the initial map set after two calls with the same list" do
      set = MapSet.new([:a, :b])

      assert set |> toggle_all([:b, :c]) |> toggle_all([:b, :c]) == set
    end

    test "returns the same result as one call to toggle/2 for each element" do
      set = MapSet.new([:a, :b])

      assert toggle_all(set, [:b, :c, :d]) == set |> toggle(:b) |> toggle(:c) |> toggle(:d)
    end

    test "ignores the order of the elements of the list" do
      set = MapSet.new([:a, :b])

      assert toggle_all(set, [:b, :c, :d]) == toggle_all(set, [:d, :c, :b])
    end

    test "changes no element that the list does not contain" do
      assert toggle_all(MapSet.new([:a, :b, :c]), [:b]) == MapSet.new([:a, :c])
    end

    test "treats a list inside the list as one element" do
      assert toggle_all(MapSet.new(), [[1, 2]]) == MapSet.new([[1, 2]])
      assert toggle_all(MapSet.new([[1, 2]]), [[1, 2]]) == MapSet.new()
      assert toggle_all(MapSet.new(), [[1, 2], [1, 2]]) == MapSet.new()
      assert toggle_all(MapSet.new(), [[], :a]) == MapSet.new([[], :a])
    end

    test "raises FunctionClauseError for a second argument that is not a list" do
      assert_raise FunctionClauseError, fn -> toggle_all(MapSet.new(), :a) end
      assert_raise FunctionClauseError, fn -> toggle_all(MapSet.new(), MapSet.new([:a])) end
      assert_raise FunctionClauseError, fn -> toggle_all(MapSet.new(), nil) end
    end

    test "raises FunctionClauseError for a first argument that is not a map set" do
      assert_raise FunctionClauseError, fn -> apply(&toggle_all/2, [[:a], [:b]]) end
      assert_raise FunctionClauseError, fn -> apply(&toggle_all/2, [nil, [:b]]) end
    end
  end
end
