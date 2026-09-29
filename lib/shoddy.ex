defmodule Shoddy do
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

      iex> Shoddy.then_if(42, &(&1 * 2))
      84

      iex> Shoddy.then_if("hello", &String.upcase/1)
      "HELLO"

      iex> Shoddy.then_if(true, fn _ -> :was_true end)
      :was_true

      iex> Shoddy.then_if([1, 2, 3], &length/1)
      3

      iex> Shoddy.then_if(%{a: 1}, &map_size/1)
      1

  The function returns a falsy value with no change:

      iex> Shoddy.then_if(nil, &(&1 * 2))
      nil

      iex> Shoddy.then_if(false, fn _ -> :was_true end)
      false

  Use the function in a pipeline:

      iex> 10 |> Shoddy.then_if(&(&1 + 5))
      15

      iex> nil |> Shoddy.then_if(&(&1 + 5))
      nil

  In Elixir, zero is truthy:

      iex> Shoddy.then_if(0, &(&1 + 1))
      1

  In Elixir, an empty collection is truthy:

      iex> Shoddy.then_if([], &[1 | &1])
      [1]
  """
  @spec then_if(value, (value -> result)) :: value | result when value: any(), result: any()
  def then_if(value, fun) when is_function(fun, 1) do
    if value, do: fun.(value), else: value
  end

  @doc """
  Applies a function to a value if a predicate returns a truthy value.

  The `predicate` argument controls the operation. A predicate of arity 0
  ignores the value. A predicate of arity 1 receives the value.

  If the predicate returns a truthy value, this function calls
  `fun.(value)`. If the predicate returns a falsy value, this function
  returns `value` with no change.

  ## Examples

  A predicate of arity 1 examines the value:

      iex> Shoddy.then_if(4, &(rem(&1, 2) == 0), &(&1 * 10))
      40

      iex> Shoddy.then_if(3, &(rem(&1, 2) == 0), &(&1 * 10))
      3

      iex> Shoddy.then_if("hello", &(String.length(&1) > 3), &String.upcase/1)
      "HELLO"

      iex> Shoddy.then_if("hi", &(String.length(&1) > 3), &String.upcase/1)
      "hi"

  A predicate of arity 0 uses a condition that is external to the value:

      iex> Shoddy.then_if(42, fn -> true end, &(&1 * 2))
      84

      iex> Shoddy.then_if(42, fn -> false end, &(&1 * 2))
      42

      iex> Shoddy.then_if(42, fn -> nil end, &(&1 * 2))
      42

  Use the function in a pipeline:

      iex> 100 |> Shoddy.then_if(&(&1 > 50), &(&1 - 50))
      50

      iex> 30 |> Shoddy.then_if(&(&1 > 50), &(&1 - 50))
      30

  A predicate of arity 1 always receives the initial value, even a falsy
  value:

      iex> Shoddy.then_if(nil, &is_nil/1, fn _ -> :was_nil end)
      :was_nil

      iex> Shoddy.then_if(false, &(&1 == false), fn _ -> :was_false end)
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

  @doc """
  Returns the value with no change.

  This function is the identity function. Use it where the code requires a
  function of arity 1 but must not change the value. `Function.identity/1`
  in the standard library is the same function, but the capture
  `&Shoddy.id/1` is shorter.

  ## Examples

      iex> Shoddy.id(42)
      42

      iex> Shoddy.id(nil)
      nil

  Use the function to keep the truthy values of a list:

      iex> Enum.filter([1, nil, 2, false, 3], &Shoddy.id/1)
      [1, 2, 3]

  Use the function to remove one level of nested lists:

      iex> Enum.flat_map([[1, 2], [], [3]], &Shoddy.id/1)
      [1, 2, 3]
  """
  @spec id(value) :: value when value: any()
  def id(value), do: value

  @doc """
  Returns the first value in a list that this function does not reject.

  The `:reject` option lists the values that this function rejects. The
  default is `[nil]`. Thus, with no options, this function returns the first
  value that is not `nil`.

  This function examines the values one after the other. If it rejects each
  value, it returns the value of the `:default` option. It also returns that
  value for an empty list.

  If a value is a function of arity 0, this function calls it one time. The
  result of that call is then the value, and this function does not call
  that result again. A function of another arity is an ordinary value.

  This function stops at the value that it returns, and it does not examine
  a later value. Thus you can put an expensive operation into a function of
  arity 0. That operation runs only if this function examines that value.

  ## Options

    * `:reject` - This option lists the values that this function rejects.
      The default is `[nil]`. This function compares two values with the
      strict equality operator `===/2`. Thus the list `[0]` does not reject
      the float `0.0`.

    * `:default` - This function returns the value of this option if it
      rejects each value in the list. The default is `nil`. This function
      does not call this value, even if it is a function of arity 0.

    * `:call_functions?` - This option is a boolean. The default is `true`.
      If this option is `false`, this function treats a function of arity 0
      as an ordinary value and does not call it.

  This function raises `ArgumentError` for an option that is not in the list
  above. It also raises `ArgumentError` for an option value of the wrong
  type.

  ## Examples

  The function returns the first value that is not `nil`:

      iex> Shoddy.coalesce([nil, nil, 3, 4])
      3

      iex> Shoddy.coalesce([1, nil, 3])
      1

  The function returns `nil` if it rejects each value:

      iex> Shoddy.coalesce([nil, nil])
      nil

      iex> Shoddy.coalesce([])
      nil

  The function calls a function of arity 0 and returns the result:

      iex> Shoddy.coalesce([nil, fn -> :computed end])
      :computed

      iex> Shoddy.coalesce([nil, fn -> nil end, :last])
      :last

  In Elixir, `false` is not `nil`, and the default list rejects only `nil`.
  Thus the function returns `false`:

      iex> Shoddy.coalesce([nil, false, :other])
      false

  The option `:reject` lists the values that the function rejects:

      iex> Shoddy.coalesce([nil, false, :other], reject: [nil, false])
      :other

      iex> Shoddy.coalesce([nil, "", "text"], reject: [nil, ""])
      "text"

  If the option `:reject` is an empty list, the function returns the first
  value:

      iex> Shoddy.coalesce([nil, :other], reject: [])
      nil

  If the function rejects each value, it returns the value of the option
  `:default`:

      iex> Shoddy.coalesce([nil, nil], default: :none)
      :none

      iex> Shoddy.coalesce([], default: 0)
      0

      iex> Shoddy.coalesce([nil, :value], default: :none)
      :value

  With `call_functions?: false`, the function treats a function of arity 0
  as an ordinary value:

      iex> fun = fn -> :computed end
      iex> Shoddy.coalesce([nil, fun], call_functions?: false) == fun
      true

  The function does not call a function of another arity:

      iex> fun = fn value -> value end
      iex> Shoddy.coalesce([nil, fun]) == fun
      true

  The function calls no function after the value that it returns:

      iex> Shoddy.coalesce([:first, fn -> send(self(), :called) end])
      :first
      iex> receive do
      ...>   :called -> :the_function_ran
      ...> after
      ...>   0 -> :the_function_did_not_run
      ...> end
      :the_function_did_not_run

  This example uses the first of three sources that has a value:

      iex> params = %{}
      iex> from_config = nil
      iex> Shoddy.coalesce([params["name"], from_config, fn -> "default" end])
      "default"
  """
  @spec coalesce([any()], keyword()) :: any()
  def coalesce(values, opts \\ []) when is_list(values) and is_list(opts) do
    opts = Keyword.validate!(opts, call_functions?: true, reject: [nil], default: nil)

    first_value(
      values,
      boolean_option!(opts, :call_functions?),
      list_option!(opts, :reject),
      Keyword.fetch!(opts, :default)
    )
  end

  defp boolean_option!(opts, key) do
    case Keyword.fetch!(opts, key) do
      value when is_boolean(value) -> value
      value -> raise ArgumentError, option_message(key, "a boolean", value)
    end
  end

  defp list_option!(opts, key) do
    case Keyword.fetch!(opts, key) do
      value when is_list(value) -> value
      value -> raise ArgumentError, option_message(key, "a list", value)
    end
  end

  defp option_message(key, expected, value) do
    "invalid value for #{inspect(key)} option: expected #{expected}, got: #{inspect(value)}"
  end

  defp first_value(values, call_functions?, reject, default) do
    Enum.reduce_while(values, default, fn value, acc ->
      result = resolve(value, call_functions?)

      if result in reject, do: {:cont, acc}, else: {:halt, result}
    end)
  end

  defp resolve(value, true) when is_function(value, 0), do: value.()
  defp resolve(value, _call_functions?), do: value
end
