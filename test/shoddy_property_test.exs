defmodule ShoddyPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  defp falsy, do: member_of([nil, false])

  defp truthy, do: filter(term(), & &1)

  describe "then_if/2" do
    property "returns a falsy value with no change" do
      check all(value <- falsy()) do
        assert Shoddy.then_if(value, fn _ -> :called end) == value
      end
    end

    property "applies the function to a truthy value" do
      check all(value <- truthy()) do
        assert Shoddy.then_if(value, fn v -> {:seen, v} end) == {:seen, value}
      end
    end

    property "does not call the function for a falsy value" do
      check all(value <- falsy()) do
        Shoddy.then_if(value, fn _ -> send(self(), :called) end)
        refute_received :called
      end
    end
  end

  describe "then_if/3" do
    property "applies the function when the predicate returns a truthy value" do
      check all(value <- term()) do
        assert Shoddy.then_if(value, fn _ -> true end, fn v -> {:seen, v} end) ==
                 {:seen, value}
      end
    end

    property "returns the value with no change when the predicate returns a falsy value" do
      check all(value <- term(), result <- falsy()) do
        assert Shoddy.then_if(value, fn _ -> result end, fn _ -> :called end) == value
      end
    end

    property "passes the value to a predicate of arity 1" do
      check all(value <- term()) do
        assert Shoddy.then_if(value, fn v -> v == value end, fn _ -> :matched end) == :matched
      end
    end

    property "applies the function for a truthy result that is not the atom true" do
      # The doc says "truthy", not "true". Every other test uses a predicate
      # that returns true, false, or nil. Thus no other test examines this rule.
      check all(value <- term(), result <- member_of([:yes, 42, "x", [], %{}, 0])) do
        assert Shoddy.then_if(value, fn -> result end, fn _ -> :called end) == :called
        assert Shoddy.then_if(value, fn _ -> result end, fn _ -> :called end) == :called
      end
    end

    property "ignores the value for a predicate of arity 0" do
      check all(value <- term(), decision <- boolean()) do
        expected = if decision, do: :called, else: value
        assert Shoddy.then_if(value, fn -> decision end, fn _ -> :called end) == expected
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
    property "returns the same result as Enum.find/2 for the first value that is not nil" do
      check all(values <- plain_values()) do
        assert Shoddy.coalesce(values) == Enum.find(values, &(&1 != nil))
      end
    end

    property "returns the same result as Enum.find/2 for the first truthy value" do
      check all(values <- plain_values()) do
        assert Shoddy.coalesce(values, reject: [nil, false]) == Enum.find(values, & &1)
      end
    end

    property "returns the same result as Enum.find/2 for any :reject option" do
      check all(values <- plain_values(), reject <- plain_values()) do
        assert Shoddy.coalesce(values, reject: reject) ==
                 Enum.find(values, &(&1 not in reject))
      end
    end

    property "returns the default if it rejects each value" do
      check all(values <- plain_values(), default <- plain_value()) do
        if Enum.all?(values, &(&1 == nil)) do
          assert Shoddy.coalesce(values, default: default) === default
        end
      end
    end

    property "returns the default if the :reject option lists every value" do
      check all(values <- plain_values(), default <- plain_value()) do
        assert Shoddy.coalesce(values, reject: values, default: default) === default
      end
    end

    property "returns the first value for an empty :reject option" do
      check all(values <- list_of(plain_value(), min_length: 1, max_length: 10)) do
        assert Shoddy.coalesce(values, reject: []) === hd(values)
      end
    end

    property "returns a value that the list contains, or nil" do
      check all(values <- plain_values()) do
        result = Shoddy.coalesce(values)

        assert result in values or result == nil
      end
    end

    property "never returns nil if the list contains a value that is not nil" do
      check all(values <- plain_values()) do
        if Enum.any?(values, &(&1 != nil)) do
          refute Shoddy.coalesce(values) == nil
        end
      end
    end

    property "never returns a falsy value with reject: [nil, false] if the list contains a truthy value" do
      check all(values <- plain_values()) do
        if Enum.any?(values, & &1) do
          assert Shoddy.coalesce(values, reject: [nil, false])
        end
      end
    end

    property "treats a function of arity 0 that returns a value in the same way as the value" do
      check all(values <- plain_values()) do
        functions = Enum.map(values, fn value -> fn -> value end end)

        assert Shoddy.coalesce(functions) == Shoddy.coalesce(values)

        assert Shoddy.coalesce(functions, reject: [nil, false]) ==
                 Shoddy.coalesce(values, reject: [nil, false])
      end
    end

    property "returns the first function with call_functions?: false" do
      check all(values <- list_of(plain_value(), min_length: 1, max_length: 10)) do
        functions = Enum.map(values, fn value -> fn -> value end end)

        assert Shoddy.coalesce(functions, call_functions?: false) == hd(functions)
      end
    end

    property "calls no function after the value that it returns" do
      check all(values <- plain_values()) do
        functions =
          Enum.with_index(values, fn value, index ->
            fn ->
              send(self(), {:called, index})
              value
            end
          end)

        Shoddy.coalesce(functions)
        called = for {:called, index} <- drain_messages(), do: index

        assert called == expected_calls(values)
      end
    end

    property "does not change a result that is not nil if more values follow at the end" do
      check all(values <- plain_values(), extra <- plain_values()) do
        result = Shoddy.coalesce(values)

        if result != nil do
          assert Shoddy.coalesce(values ++ extra) == result
        end
      end
    end
  end

  describe "id/1" do
    property "returns the same term for any term" do
      check all(value <- term()) do
        assert Shoddy.id(value) === value
      end
    end

    property "changes no list when Enum.map/2 uses it" do
      check all(list <- list_of(term(), max_length: 10)) do
        assert Enum.map(list, &Shoddy.id/1) == list
      end
    end

    property "returns the same result as Function.identity/1" do
      check all(value <- term()) do
        assert Shoddy.id(value) === Function.identity(value)
      end
    end
  end
end
