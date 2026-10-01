defmodule Shoddy.NumbersTest do
  use ExUnit.Case, async: true

  import Shoddy.Numbers

  doctest Shoddy.Numbers

  describe "ceil_div/2" do
    test "rounds up for each combination of signs" do
      assert ceil_div(7, 2) == 4
      assert ceil_div(-7, 2) == -3
      assert ceil_div(7, -2) == -3
      assert ceil_div(-7, -2) == 4
    end

    test "returns the exact quotient if the division has no remainder" do
      assert ceil_div(8, 2) == 4
      assert ceil_div(-8, 2) == -4
    end

    test "raises FunctionClauseError from ceil_div/2 itself for a zero divisor or a float" do
      for args <- [[1, 0], [1.0, 2], [1, 2.0]] do
        error = assert_raise FunctionClauseError, fn -> apply(&ceil_div/2, args) end
        assert {error.module, error.function} == {Shoddy.Numbers, :ceil_div}
      end
    end
  end

  describe "clamp/3" do
    test "returns the limits themselves at the edges" do
      assert clamp(1, 1, 3) == 1
      assert clamp(3, 1, 3) == 3
    end

    test "accepts a range of one number" do
      assert clamp(5, 2, 2) == 2
    end

    test "returns a limit as it is given, also a float" do
      assert clamp(5, 0, 3.0) === 3.0
      assert clamp(0.5, 1, 3) === 1
      assert clamp(2.5, 1, 3) === 2.5
    end

    test "raises ArgumentError if min is higher than max" do
      assert_raise ArgumentError, "the minimum 3 is higher than the maximum 1", fn -> clamp(2, 3, 1) end
    end

    test "raises FunctionClauseError from clamp/3 itself for a value that is not a number" do
      for args <- [["5", 1, 3], [5, nil, 3], [5, 1, :infinity]] do
        error = assert_raise FunctionClauseError, fn -> apply(&clamp/3, args) end
        assert {error.module, error.function} == {Shoddy.Numbers, :clamp}
      end
    end
  end

  describe "mean/1" do
    test "returns a float, also for integers" do
      assert mean([2, 4]) === {:ok, 3.0}
      assert mean([1.5]) === {:ok, 1.5}
    end

    test "raises ArithmeticError for an element that is not a number" do
      assert_raise ArithmeticError, fn -> mean([1, "2"]) end
    end

    test "raises FunctionClauseError for an argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&mean/1, [1..3]) end
    end
  end
end
