defmodule Quicksand.ResultPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Quicksand.Result

  require Result

  defp simple, do: one_of([integer(), atom(:alphanumeric), string(:alphanumeric), boolean()])

  # A result is a bare :ok, a bare :error, an ok tuple, or an error tuple.
  defp result, do: one_of([ok_result(), error_result()])

  defp ok_result, do: one_of([constant(:ok), tuple({constant(:ok), integer()})])

  defp error_result, do: one_of([constant(:error), tuple({constant(:error), simple()})])

  # This generator must make tuples as well as simple values. An earlier
  # version made only simple values. Then no property examined a tuple that is
  # not a result, and no property failed after a change removed the guard of
  # flatten/1.
  defp not_a_result do
    one_of([
      filter(simple(), fn value -> value not in [:ok, :error] end),
      tuple({member_of([:foo, :noreply, :cont]), simple()}),
      tuple({constant(:ok), simple(), simple()}),
      tuple({constant(:error), simple(), simple()})
    ])
  end

  # A functor law is a rule about a function that changes the value inside a
  # container and keeps the shape of that container. There are two such laws.
  # The composition of two functions is one function that calls the first
  # function and then calls the second function with the result.
  describe "map_ok/2 obeys the functor laws" do
    property "the identity function makes no change" do
      check all(value <- result()) do
        assert Result.map_ok(value, &Function.identity/1) == value
      end
    end

    property "two calls return the same result as one call with the composition" do
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

    property "two calls return the same result as one call with the composition" do
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
    property "left identity: an ok tuple passes its value to the function" do
      check all(value <- integer()) do
        f = fn x -> {:ok, x + 1} end
        assert Result.then_ok({:ok, value}, f) == f.(value)
      end
    end

    property "right identity: a function that only puts the value into an ok tuple makes no change" do
      check all(value <- result()) do
        assert Result.then_ok(value, &{:ok, &1}) == value
      end
    end

    property "associativity: the two ways to nest the chained calls return the same result" do
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
      # Use == false, not refute. The moduledoc states that the result is a
      # boolean. The refute macro also accepts nil, so refute cannot examine
      # this rule.
      check all(value <- not_a_result()) do
        assert Result.ok?(value) == false
        assert Result.error?(value) == false
      end
    end
  end

  describe "other operations" do
    property "ignore/1 does not change whether the result is an error" do
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

    property "from_nil/2 returns an ok result for every value that is not nil" do
      check all(value <- filter(simple(), &(not is_nil(&1))), error <- simple()) do
        assert Result.from_nil(value, error) == {:ok, value}
      end
    end

    property "from_nil/2 returns an error result for nil" do
      check all(error <- simple()) do
        assert Result.from_nil(nil, error) == {:error, error}
      end
    end

    property "flatten/1 returns a value that is not a result with no change" do
      check all(value <- not_a_result()) do
        assert Result.flatten(value) == value
      end
    end

    property "flatten/1 does not change an ok tuple that contains no result" do
      check all(inner <- not_a_result()) do
        assert Result.flatten({:ok, inner}) == {:ok, inner}
      end
    end

    property "flatten/1 removes one level from an ok tuple that contains a result" do
      check all(value <- result()) do
        assert Result.flatten({:ok, value}) == value
      end
    end
  end

  describe "guards" do
    property "is_ok/1 matches a bare :ok and an ok tuple, and nothing else" do
      # The function ok?/1 uses the guard is_ok/1. Thus a comparison with ok?/1
      # cannot find an error in the guard. This property uses a pattern match.
      check all(value <- one_of([result(), not_a_result()])) do
        guard = fn
          x when Result.is_ok(x) -> true
          _ -> false
        end

        assert guard.(value) == (value == :ok or match?({:ok, _}, value))
      end
    end

    property "is_error/1 matches a bare :error and an error tuple, and nothing else" do
      check all(value <- one_of([result(), not_a_result()])) do
        guard = fn
          x when Result.is_error(x) -> true
          _ -> false
        end

        assert guard.(value) == (value == :error or match?({:error, _}, value))
      end
    end
  end

  describe "tap_ok/2 and tap_error/2" do
    property "tap_ok/2 returns the result with no change for any return value of the function" do
      check all(value <- result(), returned <- simple()) do
        assert Result.tap_ok(value, fn _ -> returned end) == value
      end
    end

    property "tap_ok/2 calls the function one time for an ok tuple, and never for another result" do
      check all(value <- result()) do
        Result.tap_ok(value, &send(self(), {:called, &1}))

        case value do
          {:ok, inner} -> assert_received {:called, ^inner}
          _other -> :ok
        end

        refute_received {:called, _}
      end
    end

    property "tap_error/2 returns the result with no change for any return value of the function" do
      check all(value <- result(), returned <- simple()) do
        assert Result.tap_error(value, fn _ -> returned end) == value
      end
    end

    property "tap_error/2 calls the function one time for an error tuple, and never for another result" do
      check all(value <- result()) do
        Result.tap_error(value, &send(self(), {:called, &1}))

        case value do
          {:error, reason} -> assert_received {:called, ^reason}
          _other -> :ok
        end

        refute_received {:called, _}
      end
    end
  end

  describe "unwrap!/1" do
    property "raises ArgumentError for every error result" do
      check all(value <- error_result()) do
        assert_raise ArgumentError, fn -> Result.unwrap!(value) end
      end
    end

    property "returns the same value as unwrap/2 for every ok result" do
      check all(value <- ok_result()) do
        assert Result.unwrap!(value) == Result.unwrap(value, :default)
      end
    end
  end

  describe "the contract for an input that is not a result" do
    property "each function that requires a result raises FunctionClauseError for any other term" do
      calls = [
        map_ok: &Result.map_ok(&1, fn x -> x end),
        map_error: &Result.map_error(&1, fn x -> x end),
        then_ok: &Result.then_ok(&1, fn x -> {:ok, x} end),
        unwrap!: &Result.unwrap!/1,
        unwrap: &Result.unwrap(&1, :default),
        ignore: &Result.ignore/1,
        tap_ok: &Result.tap_ok(&1, fn x -> x end),
        tap_error: &Result.tap_error(&1, fn x -> x end)
      ]

      check all(value <- not_a_result()) do
        for {name, call} <- calls do
          raised =
            try do
              call.(value)
              nil
            rescue
              error -> error
            end

          assert match?(%FunctionClauseError{}, raised),
                 "#{name} did not raise FunctionClauseError for #{inspect(value)}"
        end
      end
    end
  end
end
