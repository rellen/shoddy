defmodule QuicksandPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # A falsy value is nil or false. Every other value is truthy.
  defp falsy, do: member_of([nil, false])

  defp truthy, do: filter(term(), & &1)

  describe "then_if/2" do
    property "returns a falsy value with no change" do
      check all(value <- falsy()) do
        assert Quicksand.then_if(value, fn _ -> :called end) == value
      end
    end

    property "applies the function to a truthy value" do
      check all(value <- truthy()) do
        assert Quicksand.then_if(value, fn v -> {:seen, v} end) == {:seen, value}
      end
    end

    property "does not call the function for a falsy value" do
      check all(value <- falsy()) do
        Quicksand.then_if(value, fn _ -> send(self(), :called) end)
        refute_received :called
      end
    end
  end

  describe "then_if/3" do
    property "applies the function when the predicate gives a truthy result" do
      check all(value <- term()) do
        assert Quicksand.then_if(value, fn _ -> true end, fn v -> {:seen, v} end) ==
                 {:seen, value}
      end
    end

    property "returns the value with no change when the predicate gives a falsy result" do
      check all(value <- term(), result <- falsy()) do
        assert Quicksand.then_if(value, fn _ -> result end, fn _ -> :called end) == value
      end
    end

    property "gives the value to a predicate of arity 1" do
      check all(value <- term()) do
        assert Quicksand.then_if(value, fn v -> v == value end, fn _ -> :matched end) == :matched
      end
    end

    property "ignores the value for a predicate of arity 0" do
      check all(value <- term(), decision <- boolean()) do
        expected = if decision, do: :called, else: value
        assert Quicksand.then_if(value, fn -> decision end, fn _ -> :called end) == expected
      end
    end
  end
end
