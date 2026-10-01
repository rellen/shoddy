defmodule Shoddy.Result do
  @moduledoc """
  Functions that operate on result tuples.

  A result tuple is `{:ok, value}` or `{:error, reason}`. Elixir uses these
  tuples as the usual way to show success and failure. The functions in this
  module transform, examine, and convert them. Each function takes the result
  as the first argument. Thus you can use these functions in a pipeline:

      fetch_user(id)
      |> Shoddy.Result.map_ok(& &1.name)
      |> Shoddy.Result.unwrap("unknown")

  The functions accept the bare atoms `:ok` and `:error`, and also the tuples
  `{:ok, value}` and `{:error, reason}`. A bare `:ok` has no value. Thus
  `map_ok/2` and `then_ok/2` return a bare `:ok` with no change, and
  `unwrap!/1` and `unwrap/2` accept a bare `:ok` as a success and return
  `nil`.

  Most of the functions raise `FunctionClauseError` if the input is not a
  result. A plain integer or an unrelated atom causes this error. These
  functions do not raise this error:

  - `ok?/1` and `error?/1` always return a boolean. For an input that is not
    a result, they return `false`.
  - `flatten/1` returns an input that is not a result with no change.
  - `from_nil/2` and `ensure/3` are constructors and accept all values.

  ## Constructors

  `from_nil/2` and `ensure/3` construct a result from a value and a check.
  To put a value into a result tuple with no check, use `Shoddy.Tagging.ok/1`
  and `Shoddy.Tagging.error/1`.
  """

  @typedoc "A result is an ok tuple, an error tuple, a bare `:ok`, or a bare `:error`."
  @type t :: t(any(), any())

  @typedoc "This type is a result. The caller sets the types of the value and the reason."
  @type t(value, reason) :: :ok | {:ok, value} | :error | {:error, reason}

  # Guards

  @doc """
  Tests if a result is ok.

  You can use this macro in a guard. It matches `:ok` and `{:ok, _}`.

  ## Examples

      iex> import Shoddy.Result, only: [is_ok: 1]
      iex> is_ok({:ok, 42})
      true

      iex> import Shoddy.Result, only: [is_ok: 1]
      iex> is_ok(:ok)
      true

      iex> import Shoddy.Result, only: [is_ok: 1]
      iex> is_ok({:error, :fail})
      false
  """
  defguard is_ok(result)
           when result == :ok or
                  (is_tuple(result) and tuple_size(result) == 2 and elem(result, 0) == :ok)

  @doc """
  Tests if a result is an error.

  You can use this macro in a guard. It matches `:error` and `{:error, _}`.

  ## Examples

      iex> import Shoddy.Result, only: [is_error: 1]
      iex> is_error({:error, :not_found})
      true

      iex> import Shoddy.Result, only: [is_error: 1]
      iex> is_error(:error)
      true

      iex> import Shoddy.Result, only: [is_error: 1]
      iex> is_error({:ok, 42})
      false
  """
  defguard is_error(result)
           when result == :error or
                  (is_tuple(result) and tuple_size(result) == 2 and elem(result, 0) == :error)

  # Predicates

  @doc """
  Returns `true` if the result is ok.

  This function is different from most of the functions in this module. It
  always returns a boolean, and it never raises an exception. For an input
  that is not a result, it returns `false`.

  ## Examples

      iex> Shoddy.Result.ok?({:ok, 42})
      true

      iex> Shoddy.Result.ok?(:ok)
      true

      iex> Shoddy.Result.ok?({:error, :fail})
      false

      iex> Shoddy.Result.ok?(:error)
      false

      iex> Shoddy.Result.ok?(:something_else)
      false
  """
  @spec ok?(any()) :: boolean()
  def ok?(result) when is_ok(result), do: true
  def ok?(_), do: false

  @doc """
  Returns `true` if the result is an error.

  This function is different from most of the functions in this module. It
  always returns a boolean, and it never raises an exception. For an input
  that is not a result, it returns `false`.

  ## Examples

      iex> Shoddy.Result.error?({:error, :not_found})
      true

      iex> Shoddy.Result.error?(:error)
      true

      iex> Shoddy.Result.error?({:ok, 42})
      false

      iex> Shoddy.Result.error?(:ok)
      false

      iex> Shoddy.Result.error?(:something_else)
      false
  """
  @spec error?(any()) :: boolean()
  def error?(result) when is_error(result), do: true
  def error?(_), do: false

  # Core operations

  @doc """
  Applies a function to the value in an ok tuple.

  If the result is `{:ok, value}`, this function returns `{:ok, fun.(value)}`.
  If the result is a bare `:ok`, this function returns `:ok`, because there is
  no value. This function returns an error with no change.

  The name of this function is `map_ok` and not `map`. Thus it does not
  conflict with `Enum.map/2` if you import this module.

  ## Examples

      iex> Shoddy.Result.map_ok({:ok, 3}, &(&1 * 2))
      {:ok, 6}

      iex> Shoddy.Result.map_ok({:error, :not_found}, &(&1 * 2))
      {:error, :not_found}

      iex> Shoddy.Result.map_ok(:ok, &(&1 * 2))
      :ok

      iex> Shoddy.Result.map_ok(:error, &(&1 * 2))
      :error

  Use the function in a pipeline:

      iex> {:ok, "hello"} |> Shoddy.Result.map_ok(&String.upcase/1)
      {:ok, "HELLO"}
  """
  @spec map_ok(t(a, e), (a -> b)) :: t(b, e) when a: any(), b: any(), e: any()
  def map_ok({:ok, value}, fun) when is_function(fun, 1), do: {:ok, fun.(value)}
  def map_ok(:ok, fun) when is_function(fun, 1), do: :ok
  def map_ok({:error, _} = error, fun) when is_function(fun, 1), do: error
  def map_ok(:error, fun) when is_function(fun, 1), do: :error

  @doc """
  Applies a function to the reason in an error tuple.

  If the result is `{:error, reason}`, this function returns
  `{:error, fun.(reason)}`. If the result is a bare `:error`, this function
  returns `:error`, because there is no reason. This function returns an ok
  result with no change.

  ## Examples

      iex> Shoddy.Result.map_error({:error, :not_found}, &to_string/1)
      {:error, "not_found"}

      iex> Shoddy.Result.map_error({:ok, 42}, &to_string/1)
      {:ok, 42}

      iex> Shoddy.Result.map_error(:error, &to_string/1)
      :error

      iex> Shoddy.Result.map_error(:ok, &to_string/1)
      :ok
  """
  @spec map_error(t(a, e), (e -> f)) :: t(a, f) when a: any(), e: any(), f: any()
  def map_error({:error, reason}, fun) when is_function(fun, 1), do: {:error, fun.(reason)}
  def map_error(:error, fun) when is_function(fun, 1), do: :error
  def map_error({:ok, _} = ok, fun) when is_function(fun, 1), do: ok
  def map_error(:ok, fun) when is_function(fun, 1), do: :ok

  @doc """
  Calls a function that returns a result tuple.

  If the result is `{:ok, value}`, this function calls `fun.(value)`. The
  given function must return a result tuple, but this module does not enforce
  that at run time. If the result is a bare `:ok`, this function returns
  `:ok`, because there is no value for the given function. This function
  returns an error with no change.

  In functional programming, the name of this operation is monadic bind. Other
  names are `flat_map` and `and_then`. The name `then_ok` agrees with
  `Shoddy.then_if/2`. This function calls the next function only if the
  result is ok.

  ## Examples

      iex> Shoddy.Result.then_ok({:ok, 1}, fn x -> {:ok, x + 1} end)
      {:ok, 2}

      iex> Shoddy.Result.then_ok({:ok, 1}, fn _ -> {:error, :boom} end)
      {:error, :boom}

      iex> Shoddy.Result.then_ok({:error, :fail}, fn x -> {:ok, x + 1} end)
      {:error, :fail}

      iex> Shoddy.Result.then_ok(:error, fn x -> {:ok, x + 1} end)
      :error

  This example chains two operations that can fail:

      iex> {:ok, "123"}
      ...> |> Shoddy.Result.then_ok(fn s ->
      ...>   case Integer.parse(s) do
      ...>     {n, ""} -> {:ok, n}
      ...>     _ -> {:error, :bad_integer}
      ...>   end
      ...> end)
      ...> |> Shoddy.Result.then_ok(fn n ->
      ...>   if n > 0, do: {:ok, n}, else: {:error, :not_positive}
      ...> end)
      {:ok, 123}
  """
  @spec then_ok(t(a, e), (a -> t(b, e))) :: t(b, e) when a: any(), b: any(), e: any()
  def then_ok({:ok, value}, fun) when is_function(fun, 1), do: fun.(value)
  def then_ok(:ok, fun) when is_function(fun, 1), do: :ok
  def then_ok({:error, _} = error, fun) when is_function(fun, 1), do: error
  def then_ok(:error, fun) when is_function(fun, 1), do: :error

  @doc """
  Calls a function that returns a result, for an error.

  If the result is an error, this function calls `fun.(error)` with the error
  as it is: `{:error, reason}` or a bare `:error`. The given function must
  return a result, but this module does not enforce that at run time. This
  function returns an ok result with no change, and it does not call the
  function.

  `then_ok/2` continues a pipeline after an ok result. This function continues
  a pipeline after an error. Use it to try a second source for a value after
  the first source fails, or to replace an error with a default value.

  To recover from some errors only, return each other error with no change.
  The function receives the error as it is, so a bare `:error` stays a bare
  `:error`.

  ## Examples

      iex> Shoddy.Result.recover({:error, :not_found}, fn _error -> {:ok, :default} end)
      {:ok, :default}

      iex> Shoddy.Result.recover(:error, fn _error -> {:ok, :default} end)
      {:ok, :default}

      iex> Shoddy.Result.recover({:ok, 42}, fn _error -> {:ok, :default} end)
      {:ok, 42}

      iex> Shoddy.Result.recover(:ok, fn _error -> {:ok, :default} end)
      :ok

  The function can recover from some errors only:

      iex> recover_not_found = fn
      ...>   {:error, :not_found} -> {:ok, :default}
      ...>   error -> error
      ...> end
      iex> Shoddy.Result.recover({:error, :not_found}, recover_not_found)
      {:ok, :default}
      iex> Shoddy.Result.recover({:error, :timeout}, recover_not_found)
      {:error, :timeout}
      iex> Shoddy.Result.recover(:error, recover_not_found)
      :error

  This example tries a second source if the first source fails:

      iex> from_cache = fn _key -> {:error, :miss} end
      iex> from_database = fn key -> {:ok, {:from_database, key}} end
      iex> :user
      ...> |> from_cache.()
      ...> |> Shoddy.Result.recover(fn _error -> from_database.(:user) end)
      {:ok, {:from_database, :user}}
  """
  @spec recover(t(a, e), (:error | {:error, e} -> t(a, f))) :: t(a, f)
        when a: any(), e: any(), f: any()
  def recover({:ok, _} = ok, fun) when is_function(fun, 1), do: ok
  def recover(:ok, fun) when is_function(fun, 1), do: :ok
  def recover(error, fun) when is_error(error) and is_function(fun, 1), do: fun.(error)

  @doc """
  Extracts the value from an ok tuple, or raises if the result is an error.

  This function accepts a bare `:ok` as `{:ok, nil}` and returns `nil`.

  For an error input, this function raises `ArgumentError`. The Elixir
  function `String.to_integer/1` also raises `ArgumentError` for an input that
  it cannot accept.

  ## Examples

      iex> Shoddy.Result.unwrap!({:ok, 42})
      42

      iex> Shoddy.Result.unwrap!(:ok)
      nil

      iex> Shoddy.Result.unwrap!({:error, :not_found})
      ** (ArgumentError) unwrap! called on error result: :not_found

      iex> Shoddy.Result.unwrap!(:error)
      ** (ArgumentError) unwrap! called on error result: nil
  """
  @spec unwrap!(t(a, any())) :: a when a: any()
  def unwrap!({:ok, value}), do: value
  def unwrap!(:ok), do: nil

  def unwrap!({:error, reason}), do: raise(ArgumentError, "unwrap! called on error result: #{inspect(reason)}")

  def unwrap!(:error), do: raise(ArgumentError, "unwrap! called on error result: nil")

  @doc """
  Extracts the value from an ok tuple, or returns the default if the result is
  an error.

  This function accepts a bare `:ok` as `{:ok, nil}` and returns `nil`. It
  does not return the default, because the result is still ok.

  ## Examples

      iex> Shoddy.Result.unwrap({:ok, 42}, 0)
      42

      iex> Shoddy.Result.unwrap({:error, :not_found}, 0)
      0

      iex> Shoddy.Result.unwrap(:ok, 0)
      nil

      iex> Shoddy.Result.unwrap(:error, 0)
      0
  """
  @spec unwrap(t(a, any()), b) :: a | b when a: any(), b: any()
  def unwrap({:ok, value}, _default), do: value
  def unwrap(:ok, _default), do: nil
  def unwrap({:error, _}, default), do: default
  def unwrap(:error, default), do: default

  # Conversion helpers

  @doc """
  Flattens a result tuple that contains a result tuple.

  This function converts `{:ok, {:ok, value}}` to `{:ok, value}`, and
  `{:ok, {:error, reason}}` to `{:error, reason}`. It flattens one level only.
  It returns all other values with no change.

  This module accepts the bare atoms `:ok` and `:error` as results. Thus
  `{:ok, :ok}` becomes `:ok`, and `{:ok, :error}` becomes `:error`. Do not use
  `flatten/1` if you must keep the atom `:ok` or the atom `:error` as a value
  in a result tuple.

  ## Examples

      iex> Shoddy.Result.flatten({:ok, {:ok, 42}})
      {:ok, 42}

      iex> Shoddy.Result.flatten({:ok, {:error, :fail}})
      {:error, :fail}

      iex> Shoddy.Result.flatten({:ok, 42})
      {:ok, 42}

      iex> Shoddy.Result.flatten({:error, :fail})
      {:error, :fail}

      iex> Shoddy.Result.flatten({:ok, :ok})
      :ok

      iex> Shoddy.Result.flatten({:ok, :error})
      :error

      iex> Shoddy.Result.flatten({:ok, {:ok, {:ok, 42}}})
      {:ok, {:ok, 42}}
  """
  @spec flatten(t(t(a, e), e)) :: t(a, e) when a: any(), e: any()
  def flatten({:ok, inner}) when is_ok(inner) or is_error(inner), do: inner
  def flatten(other), do: other

  @doc """
  Converts a value that can be `nil` into a result tuple.

  If the value is not `nil`, this function returns `{:ok, value}`. If the
  value is `nil`, this function returns `{:error, error}`.

  ## Examples

      iex> Shoddy.Result.from_nil(42, :not_found)
      {:ok, 42}

      iex> Shoddy.Result.from_nil(nil, :not_found)
      {:error, :not_found}

      iex> Shoddy.Result.from_nil(false, :not_found)
      {:ok, false}

  Use the function in a pipeline:

      iex> Map.get(%{a: 1}, :b) |> Shoddy.Result.from_nil(:key_missing)
      {:error, :key_missing}
  """
  @spec from_nil(a | nil, e) :: {:ok, a} | {:error, e} when a: any(), e: any()
  def from_nil(nil, error), do: {:error, error}
  def from_nil(value, _error), do: {:ok, value}

  @doc """
  Converts a value into a result tuple with a check.

  If the predicate returns a truthy value, this function returns
  `{:ok, value}`. If the predicate returns a falsy value, this function
  returns `{:error, reason}`. A truthy value is a value that is not `nil` and
  not `false`.

  A predicate of arity 1 receives the value. A predicate of arity 0 ignores
  the value, as in `Shoddy.then_if/3`.

  Use this function for a check in a pipeline, with `then_ok/2`.

  ## Examples

      iex> Shoddy.Result.ensure(36, &(&1 >= 18), :too_young)
      {:ok, 36}

      iex> Shoddy.Result.ensure(12, &(&1 >= 18), :too_young)
      {:error, :too_young}

  A predicate of arity 0 uses a condition that is external to the value:

      iex> Shoddy.Result.ensure(:delete, fn -> false end, :forbidden)
      {:error, :forbidden}

  Use the function with `then_ok/2`:

      iex> {:ok, "12"}
      ...> |> Shoddy.Result.map_ok(&String.to_integer/1)
      ...> |> Shoddy.Result.then_ok(&Shoddy.Result.ensure(&1, fn age -> age >= 18 end, :too_young))
      {:error, :too_young}
  """
  @spec ensure(a, (a -> as_boolean(any())) | (-> as_boolean(any())), e) :: {:ok, a} | {:error, e}
        when a: any(), e: any()
  def ensure(value, predicate, reason) when is_function(predicate, 0),
    do: ensure(value, fn _value -> predicate.() end, reason)

  def ensure(value, predicate, reason) when is_function(predicate, 1) do
    if predicate.(value), do: {:ok, value}, else: {:error, reason}
  end

  @doc """
  Converts `{:ok, value}` to the bare atom `:ok` and discards the value.

  This function returns an error with no change.

  ## Examples

      iex> Shoddy.Result.ignore({:ok, 42})
      :ok

      iex> Shoddy.Result.ignore(:ok)
      :ok

      iex> Shoddy.Result.ignore({:error, :fail})
      {:error, :fail}

      iex> Shoddy.Result.ignore(:error)
      :error
  """
  @spec ignore(t(any(), e)) :: :ok | :error | {:error, e} when e: any()
  def ignore({:ok, _}), do: :ok
  def ignore(:ok), do: :ok
  def ignore({:error, _} = error), do: error
  def ignore(:error), do: :error

  @doc """
  Calls a function with the value in an ok tuple, and ignores the return value.

  Use this function for a side effect, such as a log message. This function
  returns the initial result with no change. If the result is an error, this
  function does not call the given function.

  ## Examples

      iex> Shoddy.Result.tap_ok({:ok, 42}, fn val -> send(self(), {:got, val}) end)
      {:ok, 42}

      iex> Shoddy.Result.tap_ok({:error, :fail}, fn val -> send(self(), {:got, val}) end)
      {:error, :fail}

      iex> Shoddy.Result.tap_ok(:ok, fn val -> send(self(), {:got, val}) end)
      :ok
  """
  @spec tap_ok(t(a, e), (a -> any())) :: t(a, e) when a: any(), e: any()
  def tap_ok({:ok, value} = result, fun) when is_function(fun, 1) do
    fun.(value)
    result
  end

  def tap_ok(:ok, fun) when is_function(fun, 1), do: :ok
  def tap_ok({:error, _} = error, fun) when is_function(fun, 1), do: error
  def tap_ok(:error, fun) when is_function(fun, 1), do: :error

  @doc """
  Calls a function with the reason in an error tuple, and ignores the return
  value.

  Use this function for a side effect, such as a log message. This function
  returns the initial result with no change. If the result is ok, this
  function does not call the given function.

  ## Examples

      iex> Shoddy.Result.tap_error({:error, :fail}, fn reason -> send(self(), {:err, reason}) end)
      {:error, :fail}

      iex> Shoddy.Result.tap_error({:ok, 42}, fn reason -> send(self(), {:err, reason}) end)
      {:ok, 42}

      iex> Shoddy.Result.tap_error(:error, fn reason -> send(self(), {:err, reason}) end)
      :error
  """
  @spec tap_error(t(a, e), (e -> any())) :: t(a, e) when a: any(), e: any()
  def tap_error({:error, reason} = result, fun) when is_function(fun, 1) do
    fun.(reason)
    result
  end

  def tap_error(:error, fun) when is_function(fun, 1), do: :error
  def tap_error({:ok, _} = ok, fun) when is_function(fun, 1), do: ok
  def tap_error(:ok, fun) when is_function(fun, 1), do: :ok

  # Lists of results

  @doc """
  Converts a list or a stream of results into one result.

  The first argument is a list, a stream, or another struct that implements
  `Enumerable`. A map is not accepted, because its elements are key-value
  tuples and not results.

  If each element is ok, this function returns `{:ok, values}`. The list
  `values` contains the value of each element, in the order of the input. A
  bare `:ok` has no value, so it puts `nil` into the list.

  The option `:on_error` tells the function what to do for an error. The
  default is `:halt`, which returns the first error with no change.

  Use this function after `Enum.map/2` with an operation that can fail. Use
  it after `Stream.map/2` to stop the operation at the first error: with
  `on_error: :halt`, this function reads no element after the first error,
  so the stream does not call the operation for a later element. With
  another value of `:on_error`, this function reads each element until a
  function of `:on_error` returns `{:halt, error}`. Thus the stream must be
  finite.

  This function raises `FunctionClauseError` for an element that is not a
  result, if it examines that element.

  ## Options

    * `:on_error` - This option tells the function what to do for an error
      in the list. The value is one of these:

      * `:halt` - The function stops at the first error and returns it with
        no change. It does not examine a later element. This value is the
        default.

      * `:skip` - The function ignores each error. It returns the values of
        the ok elements in an ok tuple.

      * `:accumulate` - The function examines each element. If there is an
        error, it returns `{:error, reasons}`. The list `reasons` contains
        the reason of each error, in the order of the input. A bare `:error`
        has no reason, so it puts `nil` into the list.

      * A function of arity 1 - The function receives each error with no
        change. It must return one of these values:

          * `{:cont, value}` puts `value` into the list, and the function
            continues.
          * `:skip` ignores the error, and the function continues.
          * `{:halt, error}` stops the function, and the function returns
            `error`. The value `error` must be an error result.

  This function raises `ArgumentError` for an option that is not in the list
  above, and for an option value that is not in the list above. It also
  raises `ArgumentError` if the function of `:on_error` returns another
  value.

  ## Examples

      iex> Shoddy.Result.collect([{:ok, 1}, {:ok, 2}])
      {:ok, [1, 2]}

      iex> Shoddy.Result.collect([])
      {:ok, []}

      iex> Shoddy.Result.collect([{:ok, 1}, :ok])
      {:ok, [1, nil]}

  By default, the function returns the first error:

      iex> Shoddy.Result.collect([{:ok, 1}, {:error, :bad}, {:error, :worse}])
      {:error, :bad}

      iex> Shoddy.Result.collect([:error, {:ok, 1}])
      :error

  With `on_error: :skip`, the function ignores each error:

      iex> Shoddy.Result.collect([{:ok, 1}, {:error, :bad}, {:ok, 2}], on_error: :skip)
      {:ok, [1, 2]}

  With `on_error: :accumulate`, the function returns the reason of each
  error:

      iex> Shoddy.Result.collect([{:ok, 1}, {:error, :bad}, {:error, :worse}], on_error: :accumulate)
      {:error, [:bad, :worse]}

      iex> Shoddy.Result.collect([{:ok, 1}, {:ok, 2}], on_error: :accumulate)
      {:ok, [1, 2]}

  A function can put a value into the list for an error:

      iex> results = [{:ok, 1}, {:error, :bad}, {:ok, 3}]
      iex> Shoddy.Result.collect(results, on_error: fn _error -> {:cont, 0} end)
      {:ok, [1, 0, 3]}

  A function can change the error that stops the list:

      iex> results = [{:ok, 1}, {:error, :bad}, {:ok, 3}]
      iex> Shoddy.Result.collect(results, on_error: fn {:error, reason} -> {:halt, {:error, {:row, reason}}} end)
      {:error, {:row, :bad}}

  Use the function after `Enum.map/2` or `Stream.map/2`. In the last
  example, the stream does not call `parse` for `"y"`:

      iex> parse = fn text ->
      ...>   case Integer.parse(text) do
      ...>     {number, ""} -> {:ok, number}
      ...>     _other -> {:error, {:invalid, text}}
      ...>   end
      ...> end
      iex> ["1", "2", "3"] |> Enum.map(parse) |> Shoddy.Result.collect()
      {:ok, [1, 2, 3]}
      iex> ["1", "x", "y"] |> Enum.map(parse) |> Shoddy.Result.collect()
      {:error, {:invalid, "x"}}
      iex> ["1", "x", "y"] |> Enum.map(parse) |> Shoddy.Result.collect(on_error: :accumulate)
      {:error, [{:invalid, "x"}, {:invalid, "y"}]}
      iex> ["1", "x", "y"] |> Stream.map(parse) |> Shoddy.Result.collect()
      {:error, {:invalid, "x"}}

  The function stops also for an infinite stream:

      iex> Stream.concat([{:ok, 1}, {:error, :bad}], Stream.repeatedly(fn -> {:ok, 0} end))
      ...> |> Shoddy.Result.collect()
      {:error, :bad}
  """
  @spec collect([t()] | struct() | (any(), any() -> any()), keyword()) :: {:ok, [any()]} | :error | {:error, any()}
  def collect(results, opts \\ [])
      when (is_list(results) or is_struct(results) or is_function(results, 2)) and is_list(opts) do
    opts = Keyword.validate!(opts, on_error: :halt)
    collect_with(results, on_error!(opts))
  end

  @doc """
  Reduces an enumerable with a function that can fail.

  This function calls `fun` with each element and the accumulator, in order.
  `fun` must return a result:

  - `{:ok, acc}` gives the new accumulator to the next element.
  - A bare `:ok` gives `nil` as the new accumulator, as `unwrap/2` does.
  - An error result stops the reduction. This function returns the error
    with no change, and it reads no further element.

  If `fun` returns an ok result for each element, this function returns
  `{:ok, acc}` with the last accumulator. For an empty enumerable, it returns
  `{:ok, acc}` with the initial accumulator.

  `collect/2` is different. It makes a list of the values, and the elements
  do not depend on each other. Use this function if each step needs the
  result of the step before it.

  This function accepts each enumerable, also a map and a stream. It stops
  a stream at the first error. It raises `ArgumentError` if `fun` returns a
  value that is not a result.

  ## Examples

      iex> Shoddy.Result.reduce_ok([1, 2, 3], 0, fn x, sum -> {:ok, sum + x} end)
      {:ok, 6}

      iex> Shoddy.Result.reduce_ok([], 0, fn x, sum -> {:ok, sum + x} end)
      {:ok, 0}

  The function stops at the first error:

      iex> Shoddy.Result.reduce_ok(["1", "x", "y"], 0, fn text, sum ->
      ...>   text |> Shoddy.Parse.integer() |> Shoddy.Result.map_ok(&(sum + &1))
      ...> end)
      {:error, :not_an_integer}

  This example takes items from a stock. Each step needs the stock that the
  step before it left:

      iex> take = fn {item, count}, stock ->
      ...>   if Map.get(stock, item, 0) >= count,
      ...>     do: {:ok, Map.update!(stock, item, &(&1 - count))},
      ...>     else: {:error, {:not_enough, item}}
      ...> end
      iex> Shoddy.Result.reduce_ok([apple: 2, pear: 1], %{apple: 5, pear: 1}, take)
      {:ok, %{apple: 3, pear: 0}}
      iex> Shoddy.Result.reduce_ok([apple: 2, pear: 3], %{apple: 5, pear: 1}, take)
      {:error, {:not_enough, :pear}}
  """
  @spec reduce_ok(Enumerable.t(), acc, (any(), acc -> t())) :: {:ok, any()} | :error | {:error, any()}
        when acc: any()
  def reduce_ok(enumerable, acc, fun) when is_function(fun, 2) do
    Enum.reduce_while(enumerable, {:ok, acc}, fn element, {:ok, acc} ->
      case fun.(element, acc) do
        {:ok, new_acc} -> {:cont, {:ok, new_acc}}
        :ok -> {:cont, {:ok, nil}}
        error when is_error(error) -> {:halt, error}
        other -> raise ArgumentError, "invalid return value of the function: expected a result, got: #{inspect(other)}"
      end
    end)
  end

  @doc """
  Converts a map of results into one result, and keeps each error.

  If each value of the map is an ok result, this function returns
  `{:ok, map}` with the values. Otherwise, it returns `{:error, reasons}`.
  `reasons` is a map from the key of each error to its reason. A bare `:ok`
  gives the value `nil`, and a bare `:error` gives the reason `nil`.

  The function returns each error, not only the first. A map has no order
  that a program can use, so the first error has no meaning. Use this
  function to check each field of a form, and to show each error at one
  time.

  The argument must be a plain map, and each value must be a result. This
  function raises `FunctionClauseError` for a struct and for a value that
  is not a result.

  ## Examples

      iex> Shoddy.Result.collect_map(%{name: {:ok, "Ada"}, age: {:ok, 36}})
      {:ok, %{name: "Ada", age: 36}}

      iex> Shoddy.Result.collect_map(%{name: {:ok, "Ada"}, age: {:error, :too_small}, email: {:error, :missing}})
      {:error, %{age: :too_small, email: :missing}}

      iex> Shoddy.Result.collect_map(%{})
      {:ok, %{}}

  Check each field of a form:

      iex> params = %{"name" => "Ada", "age" => "x"}
      iex> %{
      ...>   name: Shoddy.Maps.fetch_keys(params, ["name"]) |> Shoddy.Result.map_ok(& &1["name"]),
      ...>   age: Shoddy.Parse.integer(params["age"])
      ...> }
      ...> |> Shoddy.Result.collect_map()
      {:error, %{age: :not_an_integer}}
  """
  @spec collect_map(%{optional(key) => t()}) :: {:ok, %{optional(key) => any()}} | {:error, %{optional(key) => any()}}
        when key: any()
  def collect_map(results) when is_map(results) and not is_struct(results) do
    {values, reasons} = Enum.reduce(results, {%{}, %{}}, &collect_entry/2)
    if map_size(reasons) == 0, do: {:ok, values}, else: {:error, reasons}
  end

  defp collect_entry({key, {:ok, value}}, {values, reasons}), do: {Map.put(values, key, value), reasons}
  defp collect_entry({key, :ok}, {values, reasons}), do: {Map.put(values, key, nil), reasons}
  defp collect_entry({key, {:error, reason}}, {values, reasons}), do: {values, Map.put(reasons, key, reason)}
  defp collect_entry({key, :error}, {values, reasons}), do: {values, Map.put(reasons, key, nil)}

  @doc """
  Calls a function, and converts the given exceptions into an error result.

  If `fun` returns a value, this function returns `{:ok, value}`. If `fun`
  raises one of the exceptions in the option `:rescue`, this function
  returns `{:error, exception}`. Each other exception continues with its
  stacktrace, as if no `try` were present.

  The option `:rescue` is required. It is a list of exception modules, such
  as `[ArgumentError]`. This function never rescues each exception, because
  an unexpected exception is usually a defect in the program, and a result
  would hide it.

  This function puts each return value into an ok tuple, also a result. To
  remove the extra tuple, call `flatten/1` on the result.

  This function raises `ArgumentError` for an unknown option, for an absent
  or empty `:rescue`, and for a module in `:rescue` that is not an
  exception.

  ## Examples

      iex> Shoddy.Result.attempt(fn -> String.to_existing_atom("ok") end, rescue: [ArgumentError])
      {:ok, :ok}

      iex> {:error, %ArgumentError{}} =
      ...>   Shoddy.Result.attempt(fn -> String.to_existing_atom("shoddy_no_such_atom") end, rescue: [ArgumentError])

  An exception that is not in the list continues:

      iex> Shoddy.Result.attempt(fn -> raise "boom" end, rescue: [ArgumentError])
      ** (RuntimeError) boom
  """
  @spec attempt((-> value), keyword()) :: {:ok, value} | {:error, Exception.t()} when value: any()
  def attempt(fun, opts) when is_function(fun, 0) and is_list(opts) do
    exceptions = exceptions!(opts)

    try do
      {:ok, fun.()}
    rescue
      exception ->
        if exception.__struct__ in exceptions,
          do: {:error, exception},
          else: reraise(exception, __STACKTRACE__)
    end
  end

  defp exceptions!(opts) do
    Keyword.validate!(opts, [:rescue])
    |> Keyword.fetch(:rescue)
    |> case do
      {:ok, [_ | _] = modules} ->
        Enum.each(modules, &exception_module!/1)
        modules

      other ->
        raise ArgumentError,
              "the option :rescue must be a non-empty list of exception modules, got: #{inspect(other)}"
    end
  end

  defp exception_module!(module) do
    if not (is_atom(module) and Code.ensure_loaded?(module) and function_exported?(module, :exception, 1)) do
      raise ArgumentError, "#{inspect(module)} in the option :rescue is not an exception module"
    end
  end

  defp on_error!(opts) do
    case Keyword.fetch!(opts, :on_error) do
      mode when mode in [:halt, :skip, :accumulate] ->
        mode

      fun when is_function(fun, 1) ->
        fun

      value ->
        raise ArgumentError,
              "invalid value for :on_error option: expected :halt, :skip, :accumulate " <>
                "or a function of arity 1, got: #{inspect(value)}"
    end
  end

  defp collect_with(results, :accumulate) do
    case Enum.reduce(results, {[], []}, &accumulate/2) do
      {values, []} -> {:ok, Enum.reverse(values)}
      {_values, reasons} -> {:error, Enum.reverse(reasons)}
    end
  end

  defp collect_with(results, on_error) do
    handler = error_handler(on_error)

    case Enum.reduce_while(results, [], &collect_value(&1, &2, handler)) do
      values when is_list(values) -> {:ok, Enum.reverse(values)}
      {:halted, error} -> error
    end
  end

  defp error_handler(:halt), do: &{:halt, &1}
  defp error_handler(:skip), do: fn _error -> :skip end
  defp error_handler(fun), do: fun

  defp collect_value({:ok, value}, values, _handler), do: {:cont, [value | values]}
  defp collect_value(:ok, values, _handler), do: {:cont, [nil | values]}

  defp collect_value(error, values, handler) when is_error(error) do
    case handler.(error) do
      {:cont, value} ->
        {:cont, [value | values]}

      :skip ->
        {:cont, values}

      {:halt, halt_error} when is_error(halt_error) ->
        {:halt, {:halted, halt_error}}

      other ->
        raise ArgumentError,
              "invalid return value of the :on_error function: expected {:cont, value}, " <>
                ":skip or {:halt, error}, got: #{inspect(other)}"
    end
  end

  defp accumulate({:ok, value}, {values, reasons}), do: {[value | values], reasons}
  defp accumulate(:ok, {values, reasons}), do: {[nil | values], reasons}
  defp accumulate({:error, reason}, {values, reasons}), do: {values, [reason | reasons]}
  defp accumulate(:error, {values, reasons}), do: {values, [nil | reasons]}
end
