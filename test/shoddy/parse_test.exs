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

  describe "float/2" do
    test "accepts a sign, a fractional part, an exponent and an integer" do
      assert float("-1.25") == {:ok, -1.25}
      assert float("1.0e-2") == {:ok, 0.01}
      assert float("7") == {:ok, 7.0}
    end

    test "returns :not_a_float for text that is not only a number" do
      for text <- ["", "1.5 kg", " 1.5", ".5", "1.", "abc", "1,5"] do
        assert float(text) == {:error, :not_a_float}, "for #{inspect(text)}"
      end
    end

    test "checks the limits, which can be integers or floats" do
      assert float("0.5", min: 1) == {:error, :too_small}
      assert float("1.5", max: 1.25) == {:error, :too_large}
      assert float("1.0", min: 1, max: 1.0) == {:ok, 1.0}
    end

    test "raises ArgumentError for a wrong option" do
      assert_raise ArgumentError, fn -> float("1", minimum: 0) end
      assert_raise ArgumentError, ~r/expected a number or nil/, fn -> float("1", min: "0") end
      assert_raise ArgumentError, ~r/higher than/, fn -> float("1", min: 2.0, max: 1) end
    end

    test "raises FunctionClauseError from float/2 itself for an argument of the wrong type" do
      for args <- [[1.5, []], [nil, []], ["1", :min]] do
        error = assert_raise FunctionClauseError, fn -> apply(&float/2, args) end
        assert {error.module, error.function} == {Shoddy.Parse, :float}
      end
    end
  end

  describe "boolean/2" do
    test "accepts only true and false by default" do
      assert boolean("true") == {:ok, true}
      assert boolean("false") == {:ok, false}

      for text <- ["TRUE", "1", "on", "yes", "", " true"] do
        assert boolean(text) == {:error, :not_a_boolean}, "for #{inspect(text)}"
      end
    end

    test "accepts the texts of the options, and only those" do
      opts = [true_values: ["1", "on"], false_values: ["0"]]

      assert boolean("on", opts) == {:ok, true}
      assert boolean("0", opts) == {:ok, false}
      assert boolean("true", opts) == {:error, :not_a_boolean}
    end

    test "accepts an empty list for one option" do
      assert boolean("false", true_values: []) == {:ok, false}
      assert boolean("true", true_values: []) == {:error, :not_a_boolean}
    end

    test "raises ArgumentError for a wrong option" do
      assert_raise ArgumentError, fn -> boolean("true", truthy: ["1"]) end
      assert_raise ArgumentError, ~r/expected a list of strings/, fn -> boolean("true", true_values: "1") end
      assert_raise ArgumentError, ~r/expected a list of strings/, fn -> boolean("true", false_values: [0]) end

      assert_raise ArgumentError, ~r/"x" is in :true_values and in :false_values/, fn ->
        boolean("true", true_values: ["x"], false_values: ["x"])
      end
    end

    test "raises FunctionClauseError from boolean/2 itself for an argument of the wrong type" do
      for args <- [[true, []], [nil, []], ["true", :opts]] do
        error = assert_raise FunctionClauseError, fn -> apply(&boolean/2, args) end
        assert {error.module, error.function} == {Shoddy.Parse, :boolean}
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
