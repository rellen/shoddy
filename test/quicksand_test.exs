defmodule QuicksandTest do
  use ExUnit.Case, async: true

  doctest Quicksand

  describe "then_if/2" do
    test "raises FunctionClauseError for a falsy value and a second argument that is not a function" do
      # A falsy value takes the branch that does not call the function. Only
      # the guard can reject an incorrect second argument for such a value.
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

  # Some tests below call a function through apply/2. The compiler examines
  # the type of each argument at a direct call. It reports a type violation
  # for an argument that no clause of the function accepts. Those tests must
  # pass such an argument, because they examine the behaviour at run time.
  # The compiler does not examine the arguments of apply/2.
  describe "coalesce/2" do
    test "returns the first value that is not nil" do
      assert Quicksand.coalesce([nil, nil, 3, 4]) == 3
      assert Quicksand.coalesce([1, nil, 3]) == 1
      assert Quicksand.coalesce([:only]) == :only
    end

    test "returns nil if each value is nil" do
      assert Quicksand.coalesce([nil, nil, nil]) == nil
      assert Quicksand.coalesce([nil]) == nil
    end

    test "returns nil for an empty list" do
      assert Quicksand.coalesce([]) == nil
      assert Quicksand.coalesce([], reject: [nil, false]) == nil
      assert Quicksand.coalesce([], call_functions?: false) == nil
    end

    test "calls a function of arity 0 and returns the result" do
      assert Quicksand.coalesce([nil, fn -> :computed end]) == :computed
      assert Quicksand.coalesce([fn -> 1 end, 2]) == 1
    end

    test "continues if a function of arity 0 returns nil" do
      assert Quicksand.coalesce([nil, fn -> nil end, :last]) == :last
      assert Quicksand.coalesce([fn -> nil end, fn -> nil end]) == nil
    end

    test "does not call the result of a function of arity 0" do
      inner = fn -> :inner end

      assert Quicksand.coalesce([fn -> inner end]) == inner
    end

    test "does not call a function of another arity" do
      fun1 = fn value -> value end
      fun2 = fn a, b -> {a, b} end

      assert Quicksand.coalesce([nil, fun1]) == fun1
      assert Quicksand.coalesce([nil, fun2]) == fun2
    end

    test "returns false, because the default list rejects only nil" do
      assert Quicksand.coalesce([nil, false, :other]) == false
      assert Quicksand.coalesce([false]) == false
      assert Quicksand.coalesce([nil, fn -> false end, :other]) == false
    end

    test "returns zero, an empty string, and an empty collection" do
      assert Quicksand.coalesce([nil, 0]) == 0
      assert Quicksand.coalesce([nil, ""]) == ""
      assert Quicksand.coalesce([nil, []]) == []
      assert Quicksand.coalesce([nil, %{}]) == %{}
    end

    test "calls no function after the value that it returns" do
      Quicksand.coalesce([:first, fn -> send(self(), :called) end])

      refute_received :called
    end

    test "calls no function after a function that returns a value" do
      Quicksand.coalesce([fn -> :first end, fn -> send(self(), :called) end])

      refute_received :called
    end

    test "calls each function before the value that it returns" do
      first = fn ->
        send(self(), :one)
        nil
      end

      second = fn ->
        send(self(), :two)
        nil
      end

      assert Quicksand.coalesce([first, second, :last]) == :last
      assert_received :one
      assert_received :two
    end

    test "rejects each value that the :reject option lists" do
      assert Quicksand.coalesce([nil, false, :other], reject: [nil, false]) == :other
      assert Quicksand.coalesce([nil, "", "text"], reject: [nil, ""]) == "text"
      assert Quicksand.coalesce([1, 2, 3], reject: [1, 2]) == 3
      assert Quicksand.coalesce([nil, fn -> false end, :other], reject: [nil, false]) == :other
    end

    test "rejects only the values that the :reject option lists, so it can keep nil" do
      assert Quicksand.coalesce([:skip, :keep], reject: [:skip]) == :keep
      assert Quicksand.coalesce([nil, :keep], reject: [:skip]) == nil
    end

    test "returns the first value for an empty :reject option" do
      assert Quicksand.coalesce([nil, :other], reject: []) == nil
      assert Quicksand.coalesce([false, :other], reject: []) == false
    end

    test "returns the default if the :reject option lists each value" do
      assert Quicksand.coalesce([nil, false], reject: [nil, false]) == nil
      assert Quicksand.coalesce([:a, :b], reject: [:a, :b]) == nil
    end

    test "compares a value to reject with the strict equality operator" do
      assert Quicksand.coalesce([0.0, :other], reject: [0]) == 0.0
      assert Quicksand.coalesce([0, :other], reject: [0]) == :other
      assert Quicksand.coalesce([1.0, :other], reject: [1.0]) == :other
    end

    test "returns the value of the :default option if it rejects each value" do
      assert Quicksand.coalesce([nil, nil], default: :none) == :none
      assert Quicksand.coalesce([], default: 0) == 0
      assert Quicksand.coalesce([nil], default: false) == false
      assert Quicksand.coalesce([:a], reject: [:a], default: :none) == :none
    end

    test "ignores the :default option if it does not reject a value" do
      assert Quicksand.coalesce([nil, :value], default: :none) == :value
      assert Quicksand.coalesce([false], default: :none) == false
    end

    test "does not call a :default option that is a function of arity 0" do
      fun = fn -> :computed end

      assert Quicksand.coalesce([nil], default: fun) == fun
      assert Quicksand.coalesce([], default: fun) == fun
    end

    test "treats a function of arity 0 as an ordinary value with call_functions?: false" do
      fun = fn -> :computed end

      assert Quicksand.coalesce([nil, fun], call_functions?: false) == fun
      assert Quicksand.coalesce([fun, :other], call_functions?: false) == fun
    end

    test "calls no function with call_functions?: false" do
      Quicksand.coalesce([fn -> send(self(), :called) end], call_functions?: false)

      refute_received :called
    end

    test "accepts every option together" do
      fun = fn -> :computed end

      assert Quicksand.coalesce([nil, false, fun],
               call_functions?: false,
               reject: [nil, false],
               default: :none
             ) == fun

      assert Quicksand.coalesce([nil, false],
               call_functions?: true,
               reject: [nil, false],
               default: :none
             ) == :none
    end

    test "accepts an explicit default for each option" do
      assert Quicksand.coalesce([nil, false, :other],
               call_functions?: true,
               reject: [nil],
               default: nil
             ) == false
    end

    test "raises ArgumentError for an option that it does not define" do
      assert_raise ArgumentError, fn -> Quicksand.coalesce([nil], unknown: true) end
      assert_raise ArgumentError, fn -> Quicksand.coalesce([nil], truthy: true) end
      assert_raise ArgumentError, fn -> Quicksand.coalesce([nil], call_functions: true) end
      assert_raise ArgumentError, fn -> Quicksand.coalesce([nil], reject: [], unknown: 1) end
    end

    test "raises ArgumentError for a :reject option that is not a list" do
      assert_raise ArgumentError, ~r/expected a list, got: nil/, fn ->
        Quicksand.coalesce([:a], reject: nil)
      end

      assert_raise ArgumentError, ~r/:reject option/, fn ->
        Quicksand.coalesce([:a], reject: :nil_only)
      end
    end

    test "raises ArgumentError for a :call_functions? option that is not a boolean" do
      assert_raise ArgumentError, ~r/expected a boolean, got: :yes/, fn ->
        Quicksand.coalesce([:a], call_functions?: :yes)
      end

      assert_raise ArgumentError, ~r/:call_functions\? option/, fn ->
        Quicksand.coalesce([:a], call_functions?: 1)
      end
    end

    test "examines an option value before it examines the list" do
      assert_raise ArgumentError, fn -> Quicksand.coalesce([], reject: :nil_only) end
      assert_raise ArgumentError, fn -> Quicksand.coalesce([], call_functions?: :yes) end
      assert_raise ArgumentError, fn -> Quicksand.coalesce([], call_functions?: nil) end
    end

    test "raises FunctionClauseError for a first argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&Quicksand.coalesce/1, [%{a: 1}]) end
      assert_raise FunctionClauseError, fn -> apply(&Quicksand.coalesce/1, [nil]) end
      assert_raise FunctionClauseError, fn -> apply(&Quicksand.coalesce/1, [:a]) end
    end

    test "raises FunctionClauseError for options that are not a list" do
      assert_raise FunctionClauseError, fn -> apply(&Quicksand.coalesce/2, [[nil], :reject]) end
    end
  end

  describe "id/1" do
    test "returns the value with no change" do
      assert Quicksand.id(42) == 42
      assert Quicksand.id("text") == "text"
      assert Quicksand.id([1, 2]) == [1, 2]
      assert Quicksand.id(%{a: 1}) == %{a: 1}
    end

    test "returns nil and false with no change" do
      assert Quicksand.id(nil) == nil
      assert Quicksand.id(false) == false
    end

    test "returns a term that is strictly equal to the argument" do
      assert Quicksand.id(1.0) === 1.0
      refute Quicksand.id(1.0) === 1
    end

    test "returns a function and does not call it" do
      fun = fn -> :called end

      assert Quicksand.id(fun) == fun
    end

    test "operates as a capture where the code requires a function of arity 1" do
      assert Enum.map([1, 2, 3], &Quicksand.id/1) == [1, 2, 3]
      assert Enum.filter([1, nil, 2, false], &Quicksand.id/1) == [1, 2]
      assert Quicksand.then_if(42, &Quicksand.id/1) == 42
    end
  end
end
