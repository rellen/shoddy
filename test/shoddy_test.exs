defmodule ShoddyTest do
  use ExUnit.Case, async: true

  doctest Shoddy

  describe "then_if/2" do
    test "raises FunctionClauseError for a falsy value and a second argument that is not a function" do
      # A falsy value takes the branch that does not call the function. Only
      # the guard can reject an incorrect second argument for such a value.
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(nil, :not_a_function) end
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(false, :not_a_function) end
    end

    test "raises FunctionClauseError for a falsy value and a function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(nil, fn -> :zero end) end
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(nil, fn _a, _b -> :two end) end
    end

    test "raises FunctionClauseError for a truthy value and a function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(42, fn _a, _b -> :two end) end
    end
  end

  describe "then_if/3" do
    test "raises FunctionClauseError for a predicate that is not a function" do
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(42, :not_a_function, & &1) end
    end

    test "raises FunctionClauseError for a predicate of arity 2" do
      assert_raise FunctionClauseError, fn ->
        Shoddy.then_if(42, fn _a, _b -> true end, & &1)
      end
    end

    test "raises FunctionClauseError for a third argument that is not a function" do
      assert_raise FunctionClauseError, fn -> Shoddy.then_if(42, fn -> true end, :not_a_fun) end
    end
  end

  # Some tests below call a function through apply/2. The compiler examines
  # the type of each argument at a direct call. It reports a type violation
  # for an argument that no clause of the function accepts. Those tests must
  # pass such an argument, because they examine the behaviour at run time.
  # The compiler does not examine the arguments of apply/2.
  describe "coalesce/2" do
    test "returns the first value that is not nil" do
      assert Shoddy.coalesce([nil, nil, 3, 4]) == 3
      assert Shoddy.coalesce([1, nil, 3]) == 1
      assert Shoddy.coalesce([:only]) == :only
    end

    test "returns nil if each value is nil" do
      assert Shoddy.coalesce([nil, nil, nil]) == nil
      assert Shoddy.coalesce([nil]) == nil
    end

    test "returns nil for an empty list" do
      assert Shoddy.coalesce([]) == nil
      assert Shoddy.coalesce([], reject: [nil, false]) == nil
      assert Shoddy.coalesce([], call_functions?: false) == nil
    end

    test "calls a function of arity 0 and returns the result" do
      assert Shoddy.coalesce([nil, fn -> :computed end]) == :computed
      assert Shoddy.coalesce([fn -> 1 end, 2]) == 1
    end

    test "continues if a function of arity 0 returns nil" do
      assert Shoddy.coalesce([nil, fn -> nil end, :last]) == :last
      assert Shoddy.coalesce([fn -> nil end, fn -> nil end]) == nil
    end

    test "does not call the result of a function of arity 0" do
      inner = fn -> :inner end

      assert Shoddy.coalesce([fn -> inner end]) == inner
    end

    test "does not call a function of another arity" do
      fun1 = fn value -> value end
      fun2 = fn a, b -> {a, b} end

      assert Shoddy.coalesce([nil, fun1]) == fun1
      assert Shoddy.coalesce([nil, fun2]) == fun2
    end

    test "returns false, because the default list rejects only nil" do
      assert Shoddy.coalesce([nil, false, :other]) == false
      assert Shoddy.coalesce([false]) == false
      assert Shoddy.coalesce([nil, fn -> false end, :other]) == false
    end

    test "returns zero, an empty string, and an empty collection" do
      assert Shoddy.coalesce([nil, 0]) == 0
      assert Shoddy.coalesce([nil, ""]) == ""
      assert Shoddy.coalesce([nil, []]) == []
      assert Shoddy.coalesce([nil, %{}]) == %{}
    end

    test "calls no function after the value that it returns" do
      Shoddy.coalesce([:first, fn -> send(self(), :called) end])

      refute_received :called
    end

    test "calls no function after a function that returns a value" do
      Shoddy.coalesce([fn -> :first end, fn -> send(self(), :called) end])

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

      assert Shoddy.coalesce([first, second, :last]) == :last
      assert_received :one
      assert_received :two
    end

    test "rejects each value that the :reject option lists" do
      assert Shoddy.coalesce([nil, false, :other], reject: [nil, false]) == :other
      assert Shoddy.coalesce([nil, "", "text"], reject: [nil, ""]) == "text"
      assert Shoddy.coalesce([1, 2, 3], reject: [1, 2]) == 3
      assert Shoddy.coalesce([nil, fn -> false end, :other], reject: [nil, false]) == :other
    end

    test "rejects only the values that the :reject option lists, so it can keep nil" do
      assert Shoddy.coalesce([:skip, :keep], reject: [:skip]) == :keep
      assert Shoddy.coalesce([nil, :keep], reject: [:skip]) == nil
    end

    test "returns the first value for an empty :reject option" do
      assert Shoddy.coalesce([nil, :other], reject: []) == nil
      assert Shoddy.coalesce([false, :other], reject: []) == false
    end

    test "returns the default if the :reject option lists each value" do
      assert Shoddy.coalesce([nil, false], reject: [nil, false]) == nil
      assert Shoddy.coalesce([:a, :b], reject: [:a, :b]) == nil
    end

    test "compares a value to reject with the strict equality operator" do
      assert Shoddy.coalesce([0.0, :other], reject: [0]) == 0.0
      assert Shoddy.coalesce([0, :other], reject: [0]) == :other
      assert Shoddy.coalesce([1.0, :other], reject: [1.0]) == :other
    end

    test "returns the value of the :default option if it rejects each value" do
      assert Shoddy.coalesce([nil, nil], default: :none) == :none
      assert Shoddy.coalesce([], default: 0) == 0
      assert Shoddy.coalesce([nil], default: false) == false
      assert Shoddy.coalesce([:a], reject: [:a], default: :none) == :none
    end

    test "ignores the :default option if it does not reject a value" do
      assert Shoddy.coalesce([nil, :value], default: :none) == :value
      assert Shoddy.coalesce([false], default: :none) == false
    end

    test "does not call a :default option that is a function of arity 0" do
      fun = fn -> :computed end

      assert Shoddy.coalesce([nil], default: fun) == fun
      assert Shoddy.coalesce([], default: fun) == fun
    end

    test "treats a function of arity 0 as an ordinary value with call_functions?: false" do
      fun = fn -> :computed end

      assert Shoddy.coalesce([nil, fun], call_functions?: false) == fun
      assert Shoddy.coalesce([fun, :other], call_functions?: false) == fun
    end

    test "calls no function with call_functions?: false" do
      Shoddy.coalesce([fn -> send(self(), :called) end], call_functions?: false)

      refute_received :called
    end

    test "accepts every option together" do
      fun = fn -> :computed end

      assert Shoddy.coalesce([nil, false, fun],
               call_functions?: false,
               reject: [nil, false],
               default: :none
             ) == fun

      assert Shoddy.coalesce([nil, false],
               call_functions?: true,
               reject: [nil, false],
               default: :none
             ) == :none
    end

    test "accepts an explicit default for each option" do
      assert Shoddy.coalesce([nil, false, :other],
               call_functions?: true,
               reject: [nil],
               default: nil
             ) == false
    end

    test "raises ArgumentError for an option that it does not define" do
      assert_raise ArgumentError, fn -> Shoddy.coalesce([nil], unknown: true) end
      assert_raise ArgumentError, fn -> Shoddy.coalesce([nil], truthy: true) end
      assert_raise ArgumentError, fn -> Shoddy.coalesce([nil], call_functions: true) end
      assert_raise ArgumentError, fn -> Shoddy.coalesce([nil], reject: [], unknown: 1) end
    end

    test "raises ArgumentError for a :reject option that is not a list" do
      assert_raise ArgumentError, ~r/expected a list, got: nil/, fn ->
        Shoddy.coalesce([:a], reject: nil)
      end

      assert_raise ArgumentError, ~r/:reject option/, fn ->
        Shoddy.coalesce([:a], reject: :nil_only)
      end
    end

    test "raises ArgumentError for a :call_functions? option that is not a boolean" do
      assert_raise ArgumentError, ~r/expected a boolean, got: :yes/, fn ->
        Shoddy.coalesce([:a], call_functions?: :yes)
      end

      assert_raise ArgumentError, ~r/:call_functions\? option/, fn ->
        Shoddy.coalesce([:a], call_functions?: 1)
      end
    end

    test "examines an option value before it examines the list" do
      assert_raise ArgumentError, fn -> Shoddy.coalesce([], reject: :nil_only) end
      assert_raise ArgumentError, fn -> Shoddy.coalesce([], call_functions?: :yes) end
      assert_raise ArgumentError, fn -> Shoddy.coalesce([], call_functions?: nil) end
    end

    test "raises FunctionClauseError for a first argument that is not a list" do
      assert_raise FunctionClauseError, fn -> apply(&Shoddy.coalesce/1, [%{a: 1}]) end
      assert_raise FunctionClauseError, fn -> apply(&Shoddy.coalesce/1, [nil]) end
      assert_raise FunctionClauseError, fn -> apply(&Shoddy.coalesce/1, [:a]) end
    end

    test "raises FunctionClauseError for options that are not a list" do
      assert_raise FunctionClauseError, fn -> apply(&Shoddy.coalesce/2, [[nil], :reject]) end
    end
  end

  describe "id/1" do
    test "returns the value with no change" do
      assert Shoddy.id(42) == 42
      assert Shoddy.id("text") == "text"
      assert Shoddy.id([1, 2]) == [1, 2]
      assert Shoddy.id(%{a: 1}) == %{a: 1}
    end

    test "returns nil and false with no change" do
      assert Shoddy.id(nil) == nil
      assert Shoddy.id(false) == false
    end

    test "returns a term that is strictly equal to the argument" do
      assert Shoddy.id(1.0) === 1.0
      refute Shoddy.id(1.0) === 1
    end

    test "returns a function and does not call it" do
      fun = fn -> :called end

      assert Shoddy.id(fun) == fun
    end

    test "operates as a capture where the code requires a function of arity 1" do
      assert Enum.map([1, 2, 3], &Shoddy.id/1) == [1, 2, 3]
      assert Enum.filter([1, nil, 2, false], &Shoddy.id/1) == [1, 2]
      assert Shoddy.then_if(42, &Shoddy.id/1) == 42
    end
  end
end
