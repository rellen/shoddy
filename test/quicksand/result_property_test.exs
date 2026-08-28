defmodule Quicksand.ResultPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Quicksand.Result

  defp simple, do: one_of([integer(), atom(:alphanumeric), string(:alphanumeric), boolean()])

  # A result is a bare :ok, a bare :error, an ok tuple, or an error tuple.
  defp result do
    one_of([
      constant(:ok),
      constant(:error),
      tuple({constant(:ok), integer()}),
      tuple({constant(:error), simple()})
    ])
  end

  # This generator must make tuples as well as simple values. A first form gave
  # simple values only, so no property saw a tuple that is not a result, and a
  # change that removed the guard of flatten/1 broke no property.
  defp not_a_result do
    one_of([
      filter(simple(), fn value -> value not in [:ok, :error] end),
      tuple({member_of([:foo, :noreply, :cont]), simple()}),
      tuple({constant(:ok), simple(), simple()})
    ])
  end

  # A functor law is a rule about a function that changes the value inside a
  # container and keeps the shape of that container. There are two such laws.
  describe "map_ok/2 obeys the functor laws" do
    property "the identity function makes no change" do
      check all(value <- result()) do
        assert Result.map_ok(value, &Function.identity/1) == value
      end
    end

    property "two applications are the same as one application of the composition" do
      check all(value <- result()) do
        f = &(&1 * 2)
        g = &(&1 + 1)

        assert value |> Result.map_ok(f) |> Result.map_ok(g) ==
                 Result.map_ok(value, fn x -> g.(f.(x)) end)
      end
    end
  end

  describe "map_error/2 obeys the functor laws" do
    property "the identity function makes no change" do
      check all(value <- result()) do
        assert Result.map_error(value, &Function.identity/1) == value
      end
    end

    property "two applications are the same as one application of the composition" do
      check all(value <- result()) do
        f = &inspect/1
        g = &String.upcase/1

        assert value |> Result.map_error(f) |> Result.map_error(g) ==
                 Result.map_error(value, fn x -> g.(f.(x)) end)
      end
    end
  end

  # A monad law is a rule about a function that chains one operation to the
  # next operation. There are three such laws. The names of the three laws are
  # left identity, right identity, and associativity.
  describe "then_ok/2 obeys the monad laws" do
    property "left identity: an ok tuple gives the value to the function" do
      check all(value <- integer()) do
        f = fn x -> {:ok, x + 1} end
        assert Result.then_ok({:ok, value}, f) == f.(value)
      end
    end

    property "right identity: a function that only puts the value back makes no change" do
      check all(value <- result()) do
        assert Result.then_ok(value, &{:ok, &1}) == value
      end
    end

    property "associativity: the order of the two chains does not matter" do
      check all(value <- result()) do
        f = fn x -> {:ok, x * 2} end
        g = fn x -> {:ok, x + 1} end

        assert value |> Result.then_ok(f) |> Result.then_ok(g) ==
                 Result.then_ok(value, fn x -> Result.then_ok(f.(x), g) end)
      end
    end
  end

  describe "predicates" do
    property "ok? and error? are never both true" do
      check all(value <- result()) do
        refute Result.ok?(value) and Result.error?(value)
      end
    end

    property "every result is an ok result or an error result" do
      check all(value <- result()) do
        assert Result.ok?(value) or Result.error?(value)
      end
    end

    property "both predicates return the atom false for a value that is not a result" do
      # Use == false, not refute. The moduledoc promises a boolean, and refute
      # also accepts nil, so refute cannot state this rule.
      check all(value <- not_a_result()) do
        assert Result.ok?(value) == false
        assert Result.error?(value) == false
      end
    end
  end

  describe "other operations" do
    property "ignore/1 keeps whether the result is an error" do
      check all(value <- result()) do
        assert Result.error?(Result.ignore(value)) == Result.error?(value)
      end
    end

    property "unwrap/2 returns the default for an error result only" do
      check all(value <- result(), default <- simple()) do
        expected =
          case value do
            {:ok, ok_value} -> ok_value
            :ok -> nil
            _error -> default
          end

        assert Result.unwrap(value, default) == expected
      end
    end

    property "from_nil/2 gives an ok result for every value that is not nil" do
      check all(value <- filter(simple(), &(not is_nil(&1))), error <- simple()) do
        assert Result.from_nil(value, error) == {:ok, value}
      end
    end

    property "from_nil/2 gives an error result for nil" do
      check all(error <- simple()) do
        assert Result.from_nil(nil, error) == {:error, error}
      end
    end

    property "flatten/1 returns a value that is not a result with no change" do
      check all(value <- not_a_result()) do
        assert Result.flatten(value) == value
      end
    end

    property "flatten/1 keeps an ok tuple that holds a value which is not a result" do
      check all(inner <- not_a_result()) do
        assert Result.flatten({:ok, inner}) == {:ok, inner}
      end
    end

    property "flatten/1 removes one level from an ok tuple that holds a result" do
      check all(value <- result()) do
        assert Result.flatten({:ok, value}) == value
      end
    end
  end
end
