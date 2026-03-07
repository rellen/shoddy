defmodule Quicksand.Result do
  @moduledoc """
  Functions for working with result tuples (`{:ok, value}` and `{:error, reason}`).

  Provides pipe-friendly operations for transforming, inspecting, and converting
  result tuples — the standard Elixir pattern for representing success and failure.

  All functions take the result as the first argument for natural use in pipelines:

      fetch_user(id)
      |> Quicksand.Result.map_ok(& &1.name)
      |> Quicksand.Result.unwrap("unknown")

  Both bare atoms (`:ok`, `:error`) and tagged tuples (`{:ok, value}`,
  `{:error, reason}`) are supported. Bare `:ok` is passed through unchanged
  by transformation functions like `map_ok/2` and `then_ok/2` (there is
  no value to transform). For `unwrap!/1` and `unwrap/2`, bare `:ok` is treated
  as success with no value, returning `nil`.

  Most functions raise `FunctionClauseError` if given a non-result input
  (e.g., a plain integer or unrelated atom). Exceptions: `ok?/1` and `error?/1`
  are total predicates that return `false` for non-results, `flatten/1` passes
  non-results through unchanged, and `from_nil/2` is a constructor that accepts
  any value.

  ## Constructors

  For constructing result tuples, see `Quicksand.Tagging.ok/1` and
  `Quicksand.Tagging.error/1`.
  """

  @typedoc "A result tuple or bare ok/error atom."
  @type t :: t(any(), any())

  @typedoc "A result with typed value and error."
  @type t(value, reason) :: :ok | {:ok, value} | :error | {:error, reason}

  # Guards

  @doc """
  A guard-safe check for ok results.

  Matches `:ok` and `{:ok, _}`.

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
  A guard-safe check for error results.

  Matches `:error` and `{:error, _}`.

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

  Unlike the other functions in this module, this is a total function —
  it returns `false` for any non-result input rather than raising.

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

  Unlike the other functions in this module, this is a total function —
  it returns `false` for any non-result input rather than raising.

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
  Applies a function to the value inside an ok tuple.

  If the result is `{:ok, value}`, returns `{:ok, fun.(value)}`.
  If the result is `:ok`, returns `:ok` (no value to map over).
  Errors are passed through unchanged.

  Named `map_ok` rather than `map` to avoid conflicts with `Enum.map/2`
  when imported.

  ## Examples

      iex> Quicksand.Result.map_ok({:ok, 3}, &(&1 * 2))
      {:ok, 6}

      iex> Quicksand.Result.map_ok({:error, :not_found}, &(&1 * 2))
      {:error, :not_found}

      iex> Quicksand.Result.map_ok(:ok, &(&1 * 2))
      :ok

      iex> Quicksand.Result.map_ok(:error, &(&1 * 2))
      :error

  Works in pipelines:

      iex> {:ok, "hello"} |> Quicksand.Result.map_ok(&String.upcase/1)
      {:ok, "HELLO"}
  """
  @spec map_ok(t(a, e), (a -> b)) :: t(b, e) when a: any(), b: any(), e: any()
  def map_ok({:ok, value}, fun) when is_function(fun, 1), do: {:ok, fun.(value)}
  def map_ok(:ok, fun) when is_function(fun, 1), do: :ok
  def map_ok({:error, _} = error, fun) when is_function(fun, 1), do: error
  def map_ok(:error, fun) when is_function(fun, 1), do: :error

  @doc """
  Applies a function to the reason inside an error tuple.

  If the result is `{:error, reason}`, returns `{:error, fun.(reason)}`.
  If the result is `:error`, returns `:error` (no reason to map over).
  Ok values are passed through unchanged.

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
  Chains a function that itself returns a result tuple.

  If the result is `{:ok, value}`, calls `fun.(value)` (which should return
  a result tuple, though this is not enforced at runtime).
  If the result is `:ok`, returns `:ok` (no value to pass to the function).
  Errors are passed through unchanged.

  Also known as monadic bind, `flat_map`, or `and_then`. Named `then_ok` to
  complement `Quicksand.then_if/2` — "if ok, then do this next thing."

  ## Examples

      iex> Quicksand.Result.then_ok({:ok, 1}, fn x -> {:ok, x + 1} end)
      {:ok, 2}

      iex> Quicksand.Result.then_ok({:ok, 1}, fn _ -> {:error, :boom} end)
      {:error, :boom}

      iex> Quicksand.Result.then_ok({:error, :fail}, fn x -> {:ok, x + 1} end)
      {:error, :fail}

      iex> Quicksand.Result.then_ok(:error, fn x -> {:ok, x + 1} end)
      :error

  Chaining multiple fallible operations:

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
  Extracts the value from an ok tuple, raising on error.

  Bare `:ok` is treated as `{:ok, nil}` and returns `nil`.

  Raises `ArgumentError` on error inputs, following the Elixir convention
  for bang functions (see `String.to_integer/1`, `URI.new!/1`).

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

  def unwrap!({:error, reason}),
    do: raise(ArgumentError, "unwrap! called on error result: #{inspect(reason)}")

  def unwrap!(:error),
    do: raise(ArgumentError, "unwrap! called on error result: nil")

  @doc """
  Extracts the value from an ok tuple, or returns the default on error.

  Bare `:ok` is treated as `{:ok, nil}` and returns `nil` (not the default,
  since the result is still ok).

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
  Flattens a nested result tuple.

  Converts `{:ok, {:ok, value}}` to `{:ok, value}` and
  `{:ok, {:error, reason}}` to `{:error, reason}`.
  Only flattens one level. Other values are returned unchanged.

  Note: because bare `:ok` and `:error` are recognized as result types,
  `{:ok, :ok}` flattens to `:ok` and `{:ok, :error}` flattens to `:error`.
  If you need to store the atoms `:ok` or `:error` as literal values inside
  a result tuple, avoid using `flatten/1`.

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
  Converts a possibly-nil value into a result tuple.

  Returns `{:ok, value}` when the value is not `nil`, or
  `{:error, error}` when it is `nil`.

  ## Examples

      iex> Quicksand.Result.from_nil(42, :not_found)
      {:ok, 42}

      iex> Quicksand.Result.from_nil(nil, :not_found)
      {:error, :not_found}

      iex> Quicksand.Result.from_nil(false, :not_found)
      {:ok, false}

  Useful in pipelines:

      iex> Map.get(%{a: 1}, :b) |> Quicksand.Result.from_nil(:key_missing)
      {:error, :key_missing}
  """
  @spec from_nil(a | nil, e) :: {:ok, a} | {:error, e} when a: any(), e: any()
  def from_nil(nil, error), do: {:error, error}
  def from_nil(value, _error), do: {:ok, value}

  @doc """
  Converts `{:ok, value}` to bare `:ok`, discarding the value.

  Errors are passed through unchanged.

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
  Runs a side-effect function on the value inside an ok tuple.

  Returns the original result unchanged. Errors are passed through without
  calling the function.

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
  Runs a side-effect function on the reason inside an error tuple.

  Returns the original result unchanged. Ok values are passed through without
  calling the function.

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
