defmodule Quicksand.ResultTest do
  use ExUnit.Case, async: true

  import Quicksand.Result

  doctest Quicksand.Result

  # Guards

  describe "is_ok/1" do
    test "matches {:ok, value}" do
      assert is_ok({:ok, 42})
    end

    test "matches bare :ok" do
      assert is_ok(:ok)
    end

    test "does not match {:error, reason}" do
      refute is_ok({:error, :fail})
    end

    test "does not match bare :error" do
      refute is_ok(:error)
    end

    test "does not match other values" do
      refute is_ok(:something)
      refute is_ok(42)
      refute is_ok({:ok, 1, 2})
    end

    test "works in guard clauses" do
      result = fn
        x when is_ok(x) -> :matched_ok
        _ -> :no_match
      end

      assert result.({:ok, 1}) == :matched_ok
      assert result.(:ok) == :matched_ok
      assert result.({:error, :fail}) == :no_match
    end
  end

  describe "is_error/1" do
    test "matches {:error, reason}" do
      assert is_error({:error, :not_found})
    end

    test "matches bare :error" do
      assert is_error(:error)
    end

    test "does not match {:ok, value}" do
      refute is_error({:ok, 42})
    end

    test "does not match bare :ok" do
      refute is_error(:ok)
    end

    test "does not match other values" do
      refute is_error(:something)
      refute is_error(42)
      refute is_error({:error, 1, 2})
    end

    test "works in guard clauses" do
      result = fn
        x when is_error(x) -> :matched_error
        _ -> :no_match
      end

      assert result.({:error, :fail}) == :matched_error
      assert result.(:error) == :matched_error
      assert result.({:ok, 1}) == :no_match
    end
  end

  # Predicates

  describe "ok?/1" do
    test "returns true for {:ok, value}" do
      assert ok?({:ok, 42})
    end

    test "returns true for bare :ok" do
      assert ok?(:ok)
    end

    test "returns false for {:error, reason}" do
      refute ok?({:error, :fail})
    end

    test "returns false for bare :error" do
      refute ok?(:error)
    end

    test "returns false for other values" do
      refute ok?(:something)
      refute ok?(42)
    end
  end

  describe "error?/1" do
    test "returns true for {:error, reason}" do
      assert error?({:error, :not_found})
    end

    test "returns true for bare :error" do
      assert error?(:error)
    end

    test "returns false for {:ok, value}" do
      refute error?({:ok, 42})
    end

    test "returns false for bare :ok" do
      refute error?(:ok)
    end

    test "returns false for other values" do
      refute error?(:something)
      refute error?(42)
    end
  end

  # Core operations

  describe "map_ok/2" do
    test "transforms the value in an ok tuple" do
      assert map_ok({:ok, 3}, &(&1 * 2)) == {:ok, 6}
    end

    test "passes through errors unchanged" do
      assert map_ok({:error, :fail}, &(&1 * 2)) == {:error, :fail}
    end

    test "transforms nil values normally" do
      assert map_ok({:ok, nil}, &is_nil/1) == {:ok, true}
    end

    test "handles bare :ok" do
      assert map_ok(:ok, &(&1 * 2)) == :ok
    end

    test "handles bare :error" do
      assert map_ok(:error, &(&1 * 2)) == :error
    end

    test "works in pipelines" do
      result =
        {:ok, "hello"}
        |> map_ok(&String.upcase/1)
        |> map_ok(&String.reverse/1)

      assert result == {:ok, "OLLEH"}
    end

    test "pipeline short-circuits on error" do
      result =
        {:error, :fail}
        |> map_ok(&(&1 + 1))
        |> map_ok(&(&1 * 2))

      assert result == {:error, :fail}
    end
  end

  describe "map_error/2" do
    test "transforms the reason in an error tuple" do
      assert map_error({:error, :not_found}, &to_string/1) == {:error, "not_found"}
    end

    test "passes through ok values unchanged" do
      assert map_error({:ok, 42}, &to_string/1) == {:ok, 42}
    end

    test "handles bare :error" do
      assert map_error(:error, &to_string/1) == :error
    end

    test "handles bare :ok" do
      assert map_error(:ok, &to_string/1) == :ok
    end
  end

  describe "then_ok/2" do
    test "chains successful operations" do
      assert then_ok({:ok, 1}, fn x -> {:ok, x + 1} end) == {:ok, 2}
    end

    test "returns error from the function" do
      assert then_ok({:ok, 1}, fn _ -> {:error, :boom} end) == {:error, :boom}
    end

    test "passes through errors without calling the function" do
      assert then_ok({:error, :fail}, fn _ -> raise "should not be called" end) ==
               {:error, :fail}
    end

    test "handles bare :ok" do
      assert then_ok(:ok, fn _ -> {:ok, 42} end) == :ok
    end

    test "handles bare :error" do
      assert then_ok(:error, fn _ -> raise "should not be called" end) == :error
    end

    test "does not enforce return type of function" do
      # The function should return a result tuple, but this is not enforced
      assert then_ok({:ok, 1}, fn x -> x + 1 end) == 2
    end

    test "chains multiple fallible operations" do
      result =
        {:ok, "42"}
        |> then_ok(fn s ->
          case Integer.parse(s) do
            {n, ""} -> {:ok, n}
            _ -> {:error, :bad_integer}
          end
        end)
        |> then_ok(fn n ->
          if n > 0, do: {:ok, n * 2}, else: {:error, :not_positive}
        end)

      assert result == {:ok, 84}
    end
  end

  describe "unwrap!/1" do
    test "extracts value from ok tuple" do
      assert unwrap!({:ok, 42}) == 42
    end

    test "extracts nil from {:ok, nil}" do
      assert unwrap!({:ok, nil}) == nil
    end

    test "returns nil for bare :ok" do
      assert unwrap!(:ok) == nil
    end

    test "raises ArgumentError on error tuple" do
      assert_raise ArgumentError, ~r/unwrap! called on error result: :fail/, fn ->
        unwrap!({:error, :fail})
      end
    end

    test "raises ArgumentError on bare :error" do
      assert_raise ArgumentError, ~r/unwrap! called on error result: nil/, fn ->
        unwrap!(:error)
      end
    end
  end

  describe "unwrap/2" do
    test "extracts value from ok tuple" do
      assert unwrap({:ok, 42}, 0) == 42
    end

    test "returns default on error tuple" do
      assert unwrap({:error, :fail}, 0) == 0
    end

    test "returns nil from {:ok, nil} not the default" do
      assert unwrap({:ok, nil}, :default) == nil
    end

    test "returns nil for bare :ok" do
      assert unwrap(:ok, 0) == nil
    end

    test "returns default on bare :error" do
      assert unwrap(:error, 0) == 0
    end
  end

  # Conversion helpers

  describe "flatten/1" do
    test "flattens nested ok" do
      assert flatten({:ok, {:ok, 42}}) == {:ok, 42}
    end

    test "flattens ok wrapping error" do
      assert flatten({:ok, {:error, :fail}}) == {:error, :fail}
    end

    test "flattens ok wrapping bare :ok" do
      assert flatten({:ok, :ok}) == :ok
    end

    test "flattens ok wrapping bare :error" do
      assert flatten({:ok, :error}) == :error
    end

    test "only flattens one level" do
      assert flatten({:ok, {:ok, {:ok, 42}}}) == {:ok, {:ok, 42}}
    end

    test "leaves non-nested ok unchanged" do
      assert flatten({:ok, 42}) == {:ok, 42}
    end

    test "leaves errors unchanged" do
      assert flatten({:error, :fail}) == {:error, :fail}
    end

    test "passes through bare :ok" do
      assert flatten(:ok) == :ok
    end

    test "passes through bare :error" do
      assert flatten(:error) == :error
    end

    test "passes through non-result values" do
      assert flatten(42) == 42
      assert flatten(:something) == :something
    end
  end

  describe "from_nil/2" do
    test "wraps non-nil value in ok tuple" do
      assert from_nil(42, :not_found) == {:ok, 42}
    end

    test "converts nil to error tuple" do
      assert from_nil(nil, :not_found) == {:error, :not_found}
    end

    test "false is not nil" do
      assert from_nil(false, :not_found) == {:ok, false}
    end

    test "nil error reason is allowed" do
      assert from_nil(nil, nil) == {:error, nil}
    end

    test "works with Map.get" do
      assert Map.get(%{a: 1}, :b) |> from_nil(:missing) == {:error, :missing}
      assert Map.get(%{a: 1}, :a) |> from_nil(:missing) == {:ok, 1}
    end
  end

  describe "ignore/1" do
    test "discards value from ok tuple" do
      assert ignore({:ok, 42}) == :ok
    end

    test "passes through bare :ok" do
      assert ignore(:ok) == :ok
    end

    test "passes through error tuple" do
      assert ignore({:error, :fail}) == {:error, :fail}
    end

    test "passes through bare :error" do
      assert ignore(:error) == :error
    end
  end

  describe "tap_ok/2" do
    test "runs side-effect on ok value and returns result" do
      assert tap_ok({:ok, 42}, fn val -> send(self(), {:got, val}) end) == {:ok, 42}
      assert_received {:got, 42}
    end

    test "does not call function on error" do
      assert tap_ok({:error, :fail}, fn _ -> send(self(), :called) end) == {:error, :fail}
      refute_received :called
    end

    test "handles bare :ok" do
      assert tap_ok(:ok, fn _ -> send(self(), :called) end) == :ok
      refute_received :called
    end

    test "handles bare :error" do
      assert tap_ok(:error, fn _ -> send(self(), :called) end) == :error
      refute_received :called
    end
  end

  describe "tap_error/2" do
    test "runs side-effect on error reason and returns result" do
      assert tap_error({:error, :fail}, fn reason -> send(self(), {:err, reason}) end) ==
               {:error, :fail}

      assert_received {:err, :fail}
    end

    test "does not call function on ok" do
      assert tap_error({:ok, 42}, fn _ -> send(self(), :called) end) == {:ok, 42}
      refute_received :called
    end

    test "handles bare :error" do
      assert tap_error(:error, fn _ -> send(self(), :called) end) == :error
      refute_received :called
    end

    test "handles bare :ok" do
      assert tap_error(:ok, fn _ -> send(self(), :called) end) == :ok
      refute_received :called
    end
  end
end
