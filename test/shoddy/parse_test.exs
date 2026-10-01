defmodule Shoddy.ParseTest do
  use ExUnit.Case, async: true

  import Shoddy.Parse

  doctest Shoddy.Parse

  describe "integer/2" do
    test "accepts a sign before the digits" do
      assert integer("+5") == {:ok, 5}
      assert integer("-5") == {:ok, -5}
      assert integer("0") == {:ok, 0}
    end

    test "accepts an integer of any size" do
      assert integer("123456789012345678901234567890") == {:ok, 123_456_789_012_345_678_901_234_567_890}
    end

    test "returns :not_an_integer for text that continues after the integer" do
      assert integer("12abc") == {:error, :not_an_integer}
      assert integer("12 ") == {:error, :not_an_integer}
      assert integer("1.5") == {:error, :not_an_integer}
      assert integer("1_000") == {:error, :not_an_integer}
    end

    test "returns :not_an_integer for text with no integer" do
      assert integer("") == {:error, :not_an_integer}
      assert integer("abc") == {:error, :not_an_integer}
      assert integer("-") == {:error, :not_an_integer}
      assert integer(" 12") == {:error, :not_an_integer}
    end

    test "accepts the limits themselves" do
      assert integer("1", min: 1, max: 3) == {:ok, 1}
      assert integer("3", min: 1, max: 3) == {:ok, 3}
    end

    test "returns :too_small and :too_large outside the limits" do
      assert integer("0", min: 1, max: 3) == {:error, :too_small}
      assert integer("4", min: 1, max: 3) == {:error, :too_large}
      assert integer("-10", min: -5) == {:error, :too_small}
      assert integer("10", max: 5) == {:error, :too_large}
    end

    test "accepts a :min that is equal to :max" do
      assert integer("7", min: 7, max: 7) == {:ok, 7}
    end

    test "returns :not_an_integer before it examines the limits" do
      assert integer("x", min: 1) == {:error, :not_an_integer}
    end

    test "accepts nil as a limit" do
      assert integer("5", min: nil, max: nil) == {:ok, 5}
    end

    test "raises ArgumentError for an unknown option" do
      assert_raise ArgumentError, fn -> integer("1", minimum: 0) end
    end

    test "raises ArgumentError for a limit that is not an integer" do
      assert_raise ArgumentError, ~r/:min option/, fn -> integer("1", min: 1.5) end
      assert_raise ArgumentError, ~r/:max option/, fn -> integer("1", max: "9") end
    end

    test "raises ArgumentError for a :min that is higher than :max" do
      assert_raise ArgumentError, ~r/higher than the option :max/, fn -> integer("1", min: 5, max: 1) end
    end

    test "raises FunctionClauseError for text that is not a binary, from integer/2 itself" do
      for args <- [[42, []], [nil, []], ["1", :min]] do
        error = assert_raise FunctionClauseError, fn -> apply(&integer/2, args) end
        assert {error.module, error.function} == {Shoddy.Parse, :integer}
      end
    end
  end

  describe "one_of/2" do
    test "returns the atom that has the text as its name" do
      assert one_of("b", [:a, :b, :c]) == {:ok, :b}
    end

    test "returns :not_allowed for text that is not the name of an allowed atom" do
      assert one_of("d", [:a, :b]) == {:error, :not_allowed}
      assert one_of("", [:a]) == {:error, :not_allowed}
      assert one_of("a", []) == {:error, :not_allowed}
    end

    test "compares the case of the letters" do
      assert one_of("A", [:a]) == {:error, :not_allowed}
    end

    test "accepts an atom with any name, also nil, true, false and an atom such as :none" do
      assert one_of("true", [true, false]) == {:ok, true}
      assert one_of("nil", [nil]) == {:ok, nil}
      assert one_of("none", [:none, :all]) == {:ok, :none}
      assert one_of("Elixir.URI", [URI]) == {:ok, URI}
    end

    test "does not make a new atom" do
      text = "shoddy_parse_test_#{System.unique_integer([:positive])}"

      assert one_of(text, [:a]) == {:error, :not_allowed}
      assert_raise ArgumentError, fn -> String.to_existing_atom(text) end
    end

    test "raises ArgumentError if an element of the allowed list is not an atom" do
      assert_raise ArgumentError, ~r/must be an atom/, fn -> one_of("a", [:a, "b"]) end
    end

    test "raises FunctionClauseError for text that is not a binary" do
      assert_raise FunctionClauseError, fn -> apply(&one_of/2, [:a, [:a]]) end
    end

    test "raises FunctionClauseError for an allowed argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&one_of/2, ["a", MapSet.new([:a])]) end
    end
  end
end
