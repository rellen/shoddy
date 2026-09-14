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

    property "applies the function for a truthy result that is not the atom true" do
      # The doc says "truthy", not "true". Every other test gives a predicate
      # that returns true, false, or nil, so no other test states this rule.
      check all(value <- term(), result <- member_of([:yes, 42, "x", [], %{}, 0])) do
        assert Quicksand.then_if(value, fn -> result end, fn _ -> :called end) == :called
        assert Quicksand.then_if(value, fn _ -> result end, fn _ -> :called end) == :called
      end
    end

    property "ignores the value for a predicate of arity 0" do
      check all(value <- term(), decision <- boolean()) do
        expected = if decision, do: :called, else: value
        assert Quicksand.then_if(value, fn -> decision end, fn _ -> :called end) == expected
      end
    end
  end

  defp plain_value do
    one_of([
      constant(nil),
      constant(false),
      integer(),
      atom(:alphanumeric),
      string(:alphanumeric)
    ])
  end

  defp plain_values, do: list_of(plain_value(), max_length: 10)

  defp drain_messages(acc \\ []) do
    receive do
      message -> drain_messages([message | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp expected_calls(values) do
    case Enum.find_index(values, &(&1 != nil)) do
      nil -> Enum.to_list(0..(length(values) - 1)//1)
      index -> Enum.to_list(0..index//1)
    end
  end

  describe "coalesce/2" do
    property "gives the same result as Enum.find/2 for the first value that is not nil" do
      check all(values <- plain_values()) do
        assert Quicksand.coalesce(values) == Enum.find(values, &(&1 != nil))
      end
    end

    property "gives the same result as Enum.find/2 for the first truthy value" do
      check all(values <- plain_values()) do
        assert Quicksand.coalesce(values, reject: [nil, false]) == Enum.find(values, & &1)
      end
    end

    property "gives the same result as Enum.find/2 for any list of values to reject" do
      check all(values <- plain_values(), reject <- plain_values()) do
        assert Quicksand.coalesce(values, reject: reject) ==
                 Enum.find(values, &(&1 not in reject))
      end
    end

    property "gives back the default if it rejects each value" do
      check all(values <- plain_values(), default <- plain_value()) do
        if Enum.all?(values, &(&1 == nil)) do
          assert Quicksand.coalesce(values, default: default) === default
        end
      end
    end

    property "rejects every value for a list of values to reject that holds them all" do
      check all(values <- plain_values(), default <- plain_value()) do
        assert Quicksand.coalesce(values, reject: values, default: default) === default
      end
    end

    property "keeps the first value for an empty list of values to reject" do
      check all(values <- list_of(plain_value(), min_length: 1, max_length: 10)) do
        assert Quicksand.coalesce(values, reject: []) === hd(values)
      end
    end

    property "gives back a value that the list contains, or nil" do
      check all(values <- plain_values()) do
        result = Quicksand.coalesce(values)

        assert result in values or result == nil
      end
    end

    property "never gives back nil if the list holds a value that is not nil" do
      check all(values <- plain_values()) do
        if Enum.any?(values, &(&1 != nil)) do
          refute Quicksand.coalesce(values) == nil
        end
      end
    end

    property "never gives back a falsy value if the list holds a truthy value" do
      check all(values <- plain_values()) do
        if Enum.any?(values, & &1) do
          assert Quicksand.coalesce(values, reject: [nil, false])
        end
      end
    end

    property "treats a function of arity 0 that gives back a value like the value" do
      check all(values <- plain_values()) do
        functions = Enum.map(values, fn value -> fn -> value end end)

        assert Quicksand.coalesce(functions) == Quicksand.coalesce(values)

        assert Quicksand.coalesce(functions, reject: [nil, false]) ==
                 Quicksand.coalesce(values, reject: [nil, false])
      end
    end

    property "gives back the first function with call_functions?: false" do
      check all(values <- list_of(plain_value(), min_length: 1, max_length: 10)) do
        functions = Enum.map(values, fn value -> fn -> value end end)

        assert Quicksand.coalesce(functions, call_functions?: false) == hd(functions)
      end
    end

    property "calls no function after the value that it gives back" do
      check all(values <- plain_values()) do
        functions =
          Enum.with_index(values, fn value, index ->
            fn ->
              send(self(), {:called, index})
              value
            end
          end)

        Quicksand.coalesce(functions)
        called = for {:called, index} <- drain_messages(), do: index

        assert called == expected_calls(values)
      end
    end

    property "keeps a result that is not nil when the list grows at the end" do
      check all(values <- plain_values(), extra <- plain_values()) do
        result = Quicksand.coalesce(values)

        if result != nil do
          assert Quicksand.coalesce(values ++ extra) == result
        end
      end
    end
  end

  describe "id/1" do
    property "gives back the same term for any term" do
      check all(value <- term()) do
        assert Quicksand.id(value) === value
      end
    end

    property "changes no list when Enum.map/2 uses it" do
      check all(list <- list_of(term(), max_length: 10)) do
        assert Enum.map(list, &Quicksand.id/1) == list
      end
    end

    property "gives the same result as Function.identity/1" do
      check all(value <- term()) do
        assert Quicksand.id(value) === Function.identity(value)
      end
    end
  end
end
