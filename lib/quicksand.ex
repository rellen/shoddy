defmodule Quicksand do
  @moduledoc """
  Small functions for tasks that occur frequently in Elixir code.
  """

  @doc """
  Applies a function to a value if the value is truthy.

  A truthy value is a value that is not `nil` and not `false`. A falsy value
  is `nil` or `false`.

  `Kernel.then/2` always calls the given function. This function calls
  `fun.(value)` only if `value` is truthy. If `value` is falsy, this function
  returns `value` with no change.

  ## Examples

  The function transforms a truthy value:

      iex> Quicksand.then_if(42, &(&1 * 2))
      84

      iex> Quicksand.then_if("hello", &String.upcase/1)
      "HELLO"

      iex> Quicksand.then_if(true, fn _ -> :was_true end)
      :was_true

      iex> Quicksand.then_if([1, 2, 3], &length/1)
      3

      iex> Quicksand.then_if(%{a: 1}, &map_size/1)
      1

  The function returns a falsy value with no change:

      iex> Quicksand.then_if(nil, &(&1 * 2))
      nil

      iex> Quicksand.then_if(false, fn _ -> :was_true end)
      false

  Use the function in a pipeline:

      iex> 10 |> Quicksand.then_if(&(&1 + 5))
      15

      iex> nil |> Quicksand.then_if(&(&1 + 5))
      nil

  In Elixir, zero is truthy:

      iex> Quicksand.then_if(0, &(&1 + 1))
      1

  In Elixir, an empty collection is truthy:

      iex> Quicksand.then_if([], &[1 | &1])
      [1]
  """
  @spec then_if(value, (value -> result)) :: value | result when value: any(), result: any()
  def then_if(value, fun) when is_function(fun, 1) do
    if value, do: fun.(value), else: value
  end

  @doc """
  Applies a function to a value if a predicate gives a truthy result.

  The `predicate` argument controls the operation. A predicate of arity 0
  ignores the value. A predicate of arity 1 receives the value.

  If the predicate gives a truthy result, this function calls `fun.(value)`.
  If not, this function returns `value` with no change.

  ## Examples

  A predicate of arity 1 examines the value:

      iex> Quicksand.then_if(4, &(rem(&1, 2) == 0), &(&1 * 10))
      40

      iex> Quicksand.then_if(3, &(rem(&1, 2) == 0), &(&1 * 10))
      3

      iex> Quicksand.then_if("hello", &(String.length(&1) > 3), &String.upcase/1)
      "HELLO"

      iex> Quicksand.then_if("hi", &(String.length(&1) > 3), &String.upcase/1)
      "hi"

  A predicate of arity 0 uses a condition that is external to the value:

      iex> Quicksand.then_if(42, fn -> true end, &(&1 * 2))
      84

      iex> Quicksand.then_if(42, fn -> false end, &(&1 * 2))
      42

      iex> Quicksand.then_if(42, fn -> nil end, &(&1 * 2))
      42

  Use the function in a pipeline:

      iex> 100 |> Quicksand.then_if(&(&1 > 50), &(&1 - 50))
      50

      iex> 30 |> Quicksand.then_if(&(&1 > 50), &(&1 - 50))
      30

  A predicate of arity 1 always receives the initial value, even a falsy
  value:

      iex> Quicksand.then_if(nil, &is_nil/1, fn _ -> :was_nil end)
      :was_nil

      iex> Quicksand.then_if(false, &(&1 == false), fn _ -> :was_false end)
      :was_false
  """
  @spec then_if(value, (value -> as_boolean(any())) | (-> as_boolean(any())), (value -> result)) ::
          value | result
        when value: any(), result: any()
  def then_if(value, predicate, fun) when is_function(predicate, 0) and is_function(fun, 1) do
    if predicate.(), do: fun.(value), else: value
  end

  def then_if(value, predicate, fun) when is_function(predicate, 1) and is_function(fun, 1) do
    if predicate.(value), do: fun.(value), else: value
  end
end
