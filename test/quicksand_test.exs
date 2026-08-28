defmodule QuicksandTest do
  use ExUnit.Case, async: true

  doctest Quicksand

  describe "then_if/2" do
    test "raises FunctionClauseError for a falsy value and a second argument that is not a function" do
      # A falsy value takes the branch that does not call the function. Only
      # the guard can reject a bad second argument for such a value.
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(nil, :not_a_function) end
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(false, :not_a_function) end
    end

    test "raises FunctionClauseError for a falsy value and a function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(nil, fn -> :zero end) end
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(nil, fn _a, _b -> :two end) end
    end

    test "raises FunctionClauseError for a truthy value and a function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(42, fn _a, _b -> :two end) end
    end
  end

  describe "then_if/3" do
    test "raises FunctionClauseError for a predicate that is not a function" do
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(42, :not_a_function, & &1) end
    end

    test "raises FunctionClauseError for a predicate of arity 2" do
      assert_raise FunctionClauseError, fn ->
        Quicksand.then_if(42, fn _a, _b -> true end, & &1)
      end
    end

    test "raises FunctionClauseError for a third argument that is not a function" do
      assert_raise FunctionClauseError, fn -> Quicksand.then_if(42, fn -> true end, :not_a_fun) end
    end
  end
end
