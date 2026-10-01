defmodule Shoddy.KeywordsTest do
  use ExUnit.Case, async: true

  import Shoddy.Keywords

  doctest Shoddy.Keywords

  describe "put_if/3" do
    test "puts a truthy value at the start of the list" do
      assert put_if([b: 2], :a, 1) == [a: 1, b: 2]
    end

    test "ignores nil and false" do
      assert put_if([b: 2], :a, nil) == [b: 2]
      assert put_if([b: 2], :a, false) == [b: 2]
    end

    test "puts zero, an empty string and an empty list, which are truthy in Elixir" do
      assert put_if([], :a, 0) == [a: 0]
      assert put_if([], :a, "") == [a: ""]
      assert put_if([], :a, []) == [a: []]
    end

    test "deletes each entry for the key when it puts a value" do
      assert put_if([a: 1, b: 2, a: 3], :a, 4) == [a: 4, b: 2]
    end

    test "keeps each entry for the key when it ignores the value" do
      assert put_if([a: 1, b: 2, a: 3], :a, nil) == [a: 1, b: 2, a: 3]
    end

    test "raises FunctionClauseError for a key that is not an atom" do
      assert_raise FunctionClauseError, fn -> apply(&put_if/3, [[], "a", 1]) end
    end

    test "raises FunctionClauseError for a first argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&put_if/3, [%{}, :a, 1]) end
    end

    test "raises FunctionClauseError for a bad argument, also if it does not put the value" do
      assert_raise FunctionClauseError, fn -> apply(&put_if/3, [[], "a", nil]) end
      assert_raise FunctionClauseError, fn -> apply(&put_if/3, [%{}, :a, nil]) end
    end
  end

  describe "put_present/3" do
    test "puts a value that is not nil at the start of the list" do
      assert put_present([b: 2], :a, 1) == [a: 1, b: 2]
    end

    test "puts false" do
      assert put_present([], :a, false) == [a: false]
    end

    test "ignores nil" do
      assert put_present([b: 2], :a, nil) == [b: 2]
    end

    test "deletes each entry for the key when it puts a value" do
      assert put_present([a: 1, b: 2, a: 3], :a, false) == [a: false, b: 2]
    end

    test "keeps each entry for the key when it ignores the value" do
      assert put_present([a: 1, b: 2, a: 3], :a, nil) == [a: 1, b: 2, a: 3]
    end

    test "raises FunctionClauseError for a key that is not an atom" do
      assert_raise FunctionClauseError, fn -> apply(&put_present/3, [[], "a", 1]) end
    end

    test "raises FunctionClauseError for a first argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&put_present/3, [%{}, :a, 1]) end
    end

    test "raises FunctionClauseError for a bad argument, also if it does not put the value" do
      assert_raise FunctionClauseError, fn -> apply(&put_present/3, [[], "a", nil]) end
      assert_raise FunctionClauseError, fn -> apply(&put_present/3, [%{}, :a, nil]) end
    end
  end

  describe "get_present/3" do
    test "returns the value of the first entry for the key" do
      assert get_present([a: 1, a: 2], :a, 0) == 1
    end

    test "returns the default for an absent key and for nil" do
      assert get_present([b: 1], :a, 0) == 0
      assert get_present([a: nil], :a, 0) == 0
    end

    test "returns false and other falsy-looking values with no change" do
      assert get_present([a: false], :a, true) == false
      assert get_present([a: 0], :a, 1) == 0
      assert get_present([a: ""], :a, "x") == ""
    end

    test "does not read a later entry if the first entry is nil" do
      assert get_present([a: nil, a: 2], :a, 0) == 0
    end

    test "returns any term as the default" do
      assert get_present([], :a, nil) == nil
      assert get_present([], :a, x: 1) == [x: 1]
    end

    test "raises FunctionClauseError for a key that is not an atom" do
      assert_raise FunctionClauseError, fn -> apply(&get_present/3, [[a: 1], "a", 0]) end
    end

    test "raises FunctionClauseError for a first argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&get_present/3, [%{a: 1}, :a, 0]) end
    end
  end
end
