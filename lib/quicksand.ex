defmodule Quicksand do
  @moduledoc """
  A grab-bag of utility functions for Elixir.
  """

  @doc """
  Conditionally applies a function to a value, like a conditional `Kernel.then/2`.

  Calls `fun.(value)` only when `value` is truthy (not `nil` or `false`).
  When `value` is falsy, it is returned unchanged.

  ## Examples

  Truthy values get transformed:

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

  Falsy values pass through unchanged:

      iex> Quicksand.then_if(nil, &(&1 * 2))
      nil

      iex> Quicksand.then_if(false, fn _ -> :was_true end)
      false

  Works naturally in pipelines:

      iex> 10 |> Quicksand.then_if(&(&1 + 5))
      15

      iex> nil |> Quicksand.then_if(&(&1 + 5))
      nil

  Zero is truthy in Elixir:

      iex> Quicksand.then_if(0, &(&1 + 1))
      1

  Empty collections are truthy:

      iex> Quicksand.then_if([], &[1 | &1])
      [1]
  """
  @spec then_if(value, (value -> result)) :: value | result when value: any(), result: any()
  def then_if(value, fun) when is_function(fun, 1) do
    if value, do: fun.(value), else: value
  end

  @doc """
  Conditionally applies a function to a value based on a predicate.

  Evaluates `predicate` to decide whether to call `fun.(value)`. The predicate
  can be a 0-arity function (ignores the value) or a 1-arity function (receives
  the value). When the predicate returns a truthy result, `fun.(value)` is called.
  Otherwise, `value` is returned unchanged.

  ## Examples

  With a 1-arity predicate that inspects the value:

      iex> Quicksand.then_if(4, &(rem(&1, 2) == 0), &(&1 * 10))
      40

      iex> Quicksand.then_if(3, &(rem(&1, 2) == 0), &(&1 * 10))
      3

      iex> Quicksand.then_if("hello", &(String.length(&1) > 3), &String.upcase/1)
      "HELLO"

      iex> Quicksand.then_if("hi", &(String.length(&1) > 3), &String.upcase/1)
      "hi"

  With a 0-arity predicate (external condition):

      iex> Quicksand.then_if(42, fn -> true end, &(&1 * 2))
      84

      iex> Quicksand.then_if(42, fn -> false end, &(&1 * 2))
      42

      iex> Quicksand.then_if(42, fn -> nil end, &(&1 * 2))
      42

  Works in pipelines:

      iex> 100 |> Quicksand.then_if(&(&1 > 50), &(&1 - 50))
      50

      iex> 30 |> Quicksand.then_if(&(&1 > 50), &(&1 - 50))
      30

  Predicate receives the original value, even when falsy:

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
