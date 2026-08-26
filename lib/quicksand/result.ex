defmodule Quicksand.Result do
  @moduledoc """
  Functions that operate on result tuples, that is `{:ok, value}` and
  `{:error, reason}`.

  Elixir uses these tuples as the usual way to show success and failure. The
  functions in this module transform, examine, and convert them. Each function
  takes the result as the first argument. Thus you can use these functions in
  a pipeline:

      fetch_user(id)
      |> Quicksand.Result.map_ok(& &1.name)
      |> Quicksand.Result.unwrap("unknown")

  The functions accept the bare atoms `:ok` and `:error`, and also the tuples
  `{:ok, value}` and `{:error, reason}`. A bare `:ok` has no value. Thus
  `map_ok/2` and `then_ok/2` return a bare `:ok` with no change, and
  `unwrap!/1` and `unwrap/2` accept a bare `:ok` as a success and return
  `nil`.

  Most of the functions raise `FunctionClauseError` if the input is not a
  result. A plain integer or an unrelated atom causes this error. There are
  three exceptions:

  - `ok?/1` and `error?/1` always return a boolean. For an input that is not
    a result, they return `false`.
  - `flatten/1` returns an input that is not a result with no change.
  - `from_nil/2` is a constructor and accepts all values.

  ## Constructors

  To construct result tuples, refer to `Quicksand.Tagging.ok/1` and
  `Quicksand.Tagging.error/1`.
  """

  @typedoc "A result tuple or a bare ok or error atom."
  @type t :: t(any(), any())

  @typedoc "A result with a typed value and a typed error."
  @type t(value, reason) :: :ok | {:ok, value} | :error | {:error, reason}

  # Guards

  @doc """
  Tests if a result is ok.

  You can use this macro in a guard. It matches `:ok` and `{:ok, _}`.

  ## Examples

      iex> import Quicksand.Result, only: [is_ok: 1]
      iex> is_ok({:ok, 42})
      true

      iex> import Quicksand.Result, only: [is_ok: 1]
      iex> is_ok(:ok)
      true

      iex> import Quicksand.Result, only: [is_ok: 1]
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

      iex> import Quicksand.Result, only: [is_error: 1]
      iex> is_error({:error, :not_found})
      true

      iex> import Quicksand.Result, only: [is_error: 1]
      iex> is_error(:error)
      true

      iex> import Quicksand.Result, only: [is_error: 1]
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
  always returns a boolean and it does not raise. For an input that is not a
  result, it returns `false`.

  ## Examples

      iex> Quicksand.Result.ok?({:ok, 42})
      true

      iex> Quicksand.Result.ok?(:ok)
      true

      iex> Quicksand.Result.ok?({:error, :fail})
      false

      iex> Quicksand.Result.ok?(:error)
      false

      iex> Quicksand.Result.ok?(:something_else)
      false
  """
  @spec ok?(any()) :: boolean()
  def ok?(result) when is_ok(result), do: true
  def ok?(_), do: false

  @doc """
  Returns `true` if the result is an error.

  This function is different from most of the functions in this module. It
  always returns a boolean and it does not raise. For an input that is not a
  result, it returns `false`.

  ## Examples

      iex> Quicksand.Result.error?({:error, :not_found})
      true

      iex> Quicksand.Result.error?(:error)
      true

      iex> Quicksand.Result.error?({:ok, 42})
      false

      iex> Quicksand.Result.error?(:ok)
      false

      iex> Quicksand.Result.error?(:something_else)
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

      iex> Quicksand.Result.map_ok({:ok, 3}, &(&1 * 2))
      {:ok, 6}

      iex> Quicksand.Result.map_ok({:error, :not_found}, &(&1 * 2))
      {:error, :not_found}

      iex> Quicksand.Result.map_ok(:ok, &(&1 * 2))
      :ok

      iex> Quicksand.Result.map_ok(:error, &(&1 * 2))
      :error

  Use the function in a pipeline:

      iex> {:ok, "hello"} |> Quicksand.Result.map_ok(&String.upcase/1)
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

      iex> Quicksand.Result.map_error({:error, :not_found}, &to_string/1)
      {:error, "not_found"}

      iex> Quicksand.Result.map_error({:ok, 42}, &to_string/1)
      {:ok, 42}

      iex> Quicksand.Result.map_error(:error, &to_string/1)
      :error

      iex> Quicksand.Result.map_error(:ok, &to_string/1)
      :ok
  """
  @spec map_error(t(a, e), (e -> f)) :: t(a, f) when a: any(), e: any(), f: any()
  def map_error({:error, reason}, fun) when is_function(fun, 1), do: {:error, fun.(reason)}
  def map_error(:error, fun) when is_function(fun, 1), do: :error
  def map_error({:ok, _} = ok, fun) when is_function(fun, 1), do: ok
  def map_error(:ok, fun) when is_function(fun, 1), do: :ok

  @doc """
  Calls a function that itself returns a result tuple.

  If the result is `{:ok, value}`, this function calls `fun.(value)`. The
  given function must return a result tuple, but this module does not enforce
  that at run time. If the result is a bare `:ok`, this function returns
  `:ok`, because there is no value for the given function. This function
  returns an error with no change.

  In functional programming, the name of this operation is monadic bind. Other
  names are `flat_map` and `and_then`. The name `then_ok` agrees with
  `Quicksand.then_if/2`. If the result is ok, then do the next operation.

  ## Examples

      iex> Quicksand.Result.then_ok({:ok, 1}, fn x -> {:ok, x + 1} end)
      {:ok, 2}

      iex> Quicksand.Result.then_ok({:ok, 1}, fn _ -> {:error, :boom} end)
      {:error, :boom}

      iex> Quicksand.Result.then_ok({:error, :fail}, fn x -> {:ok, x + 1} end)
      {:error, :fail}

      iex> Quicksand.Result.then_ok(:error, fn x -> {:ok, x + 1} end)
      :error

  This example chains two operations that can fail:

      iex> {:ok, "123"}
      ...> |> Quicksand.Result.then_ok(fn s ->
      ...>   case Integer.parse(s) do
      ...>     {n, ""} -> {:ok, n}
      ...>     _ -> {:error, :bad_integer}
      ...>   end
      ...> end)
      ...> |> Quicksand.Result.then_ok(fn n ->
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
  Extracts the value from an ok tuple, or raises if the result is an error.

  This function accepts a bare `:ok` as `{:ok, nil}` and returns `nil`.

  For an error input, this function raises `ArgumentError`. This agrees with
  the Elixir convention for functions that raise, such as
  `String.to_integer/1` and `URI.new!/1`.

  ## Examples

      iex> Quicksand.Result.unwrap!({:ok, 42})
      42

      iex> Quicksand.Result.unwrap!(:ok)
      nil

      iex> Quicksand.Result.unwrap!({:error, :not_found})
      ** (ArgumentError) unwrap! called on error result: :not_found

      iex> Quicksand.Result.unwrap!(:error)
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

      iex> Quicksand.Result.unwrap({:ok, 42}, 0)
      42

      iex> Quicksand.Result.unwrap({:error, :not_found}, 0)
      0

      iex> Quicksand.Result.unwrap(:ok, 0)
      nil

      iex> Quicksand.Result.unwrap(:error, 0)
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

  Note: this module accepts the bare atoms `:ok` and `:error` as results. Thus
  `{:ok, :ok}` becomes `:ok`, and `{:ok, :error}` becomes `:error`. Do not use
  `flatten/1` if you must keep the atom `:ok` or the atom `:error` as a value
  in a result tuple.

  ## Examples

      iex> Quicksand.Result.flatten({:ok, {:ok, 42}})
      {:ok, 42}

      iex> Quicksand.Result.flatten({:ok, {:error, :fail}})
      {:error, :fail}

      iex> Quicksand.Result.flatten({:ok, 42})
      {:ok, 42}

      iex> Quicksand.Result.flatten({:error, :fail})
      {:error, :fail}

      iex> Quicksand.Result.flatten({:ok, :ok})
      :ok

      iex> Quicksand.Result.flatten({:ok, :error})
      :error

      iex> Quicksand.Result.flatten({:ok, {:ok, {:ok, 42}}})
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

      iex> Quicksand.Result.from_nil(42, :not_found)
      {:ok, 42}

      iex> Quicksand.Result.from_nil(nil, :not_found)
      {:error, :not_found}

      iex> Quicksand.Result.from_nil(false, :not_found)
      {:ok, false}

  Use the function in a pipeline:

      iex> Map.get(%{a: 1}, :b) |> Quicksand.Result.from_nil(:key_missing)
      {:error, :key_missing}
  """
  @spec from_nil(a | nil, e) :: {:ok, a} | {:error, e} when a: any(), e: any()
  def from_nil(nil, error), do: {:error, error}
  def from_nil(value, _error), do: {:ok, value}

  @doc """
  Converts `{:ok, value}` to the bare atom `:ok` and discards the value.

  This function returns an error with no change.

  ## Examples

      iex> Quicksand.Result.ignore({:ok, 42})
      :ok

      iex> Quicksand.Result.ignore(:ok)
      :ok

      iex> Quicksand.Result.ignore({:error, :fail})
      {:error, :fail}

      iex> Quicksand.Result.ignore(:error)
      :error
  """
  @spec ignore(t(any(), e)) :: :ok | :error | {:error, e} when e: any()
  def ignore({:ok, _}), do: :ok
  def ignore(:ok), do: :ok
  def ignore({:error, _} = error), do: error
  def ignore(:error), do: :error

  @doc """
  Calls a function for its side effect on the value in an ok tuple.

  This function returns the initial result with no change. If the result is an
  error, this function does not call the given function.

  ## Examples

      iex> Quicksand.Result.tap_ok({:ok, 42}, fn val -> send(self(), {:got, val}) end)
      {:ok, 42}

      iex> Quicksand.Result.tap_ok({:error, :fail}, fn val -> send(self(), {:got, val}) end)
      {:error, :fail}

      iex> Quicksand.Result.tap_ok(:ok, fn val -> send(self(), {:got, val}) end)
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
  Calls a function for its side effect on the reason in an error tuple.

  This function returns the initial result with no change. If the result is
  ok, this function does not call the given function.

  ## Examples

      iex> Quicksand.Result.tap_error({:error, :fail}, fn reason -> send(self(), {:err, reason}) end)
      {:error, :fail}

      iex> Quicksand.Result.tap_error({:ok, 42}, fn reason -> send(self(), {:err, reason}) end)
      {:ok, 42}

      iex> Quicksand.Result.tap_error(:error, fn reason -> send(self(), {:err, reason}) end)
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
end
