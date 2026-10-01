defmodule Shoddy.ResultTest do
  use ExUnit.Case, async: true

  import Shoddy.Result

  doctest Shoddy.Result

  # Guards

  describe "is_ok/1" do
    test "matches {:ok, value}" do
      assert is_ok({:ok, 42})
    end

    test "matches a bare :ok" do
      assert is_ok(:ok)
    end

    test "does not match {:error, reason}" do
      refute is_ok({:error, :fail})
    end

    test "does not match a bare :error" do
      refute is_ok(:error)
    end

    test "does not match a value that is not a result" do
      refute is_ok(:something)
      refute is_ok(42)
      refute is_ok({:ok, 1, 2})
    end

    test "operates in a guard clause" do
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

    test "matches a bare :error" do
      assert is_error(:error)
    end

    test "does not match {:ok, value}" do
      refute is_error({:ok, 42})
    end

    test "does not match a bare :ok" do
      refute is_error(:ok)
    end

    test "does not match a value that is not a result" do
      refute is_error(:something)
      refute is_error(42)
      refute is_error({:error, 1, 2})
    end

    test "operates in a guard clause" do
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

    test "returns true for a bare :ok" do
      assert ok?(:ok)
    end

    test "returns false for {:error, reason}" do
      refute ok?({:error, :fail})
    end

    test "returns false for a bare :error" do
      refute ok?(:error)
    end

    test "returns false for a value that is not a result" do
      refute ok?(:something)
      refute ok?(42)
    end
  end

  describe "error?/1" do
    test "returns true for {:error, reason}" do
      assert error?({:error, :not_found})
    end

    test "returns true for a bare :error" do
      assert error?(:error)
    end

    test "returns false for {:ok, value}" do
      refute error?({:ok, 42})
    end

    test "returns false for a bare :ok" do
      refute error?(:ok)
    end

    test "returns false for a value that is not a result" do
      refute error?(:something)
      refute error?(42)
    end
  end

  # Core operations

  describe "map_ok/2" do
    test "transforms the value in an ok tuple" do
      assert map_ok({:ok, 3}, &(&1 * 2)) == {:ok, 6}
    end

    test "returns an error with no change" do
      assert map_ok({:error, :fail}, &(&1 * 2)) == {:error, :fail}
    end

    test "transforms a nil value" do
      assert map_ok({:ok, nil}, &is_nil/1) == {:ok, true}
    end

    test "returns a bare :ok with no change" do
      assert map_ok(:ok, &(&1 * 2)) == :ok
    end

    test "returns a bare :error with no change" do
      assert map_ok(:error, &(&1 * 2)) == :error
    end

    test "operates in a pipeline" do
      result =
        {:ok, "hello"}
        |> map_ok(&String.upcase/1)
        |> map_ok(&String.reverse/1)

      assert result == {:ok, "OLLEH"}
    end

    test "stops the pipeline at the first error" do
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

    test "returns an ok result with no change" do
      assert map_error({:ok, 42}, &to_string/1) == {:ok, 42}
    end

    test "returns a bare :error with no change" do
      assert map_error(:error, &to_string/1) == :error
    end

    test "returns a bare :ok with no change" do
      assert map_error(:ok, &to_string/1) == :ok
    end
  end

  describe "then_ok/2" do
    test "chains operations that succeed" do
      assert then_ok({:ok, 1}, fn x -> {:ok, x + 1} end) == {:ok, 2}
    end

    test "returns the error from the function" do
      assert then_ok({:ok, 1}, fn _ -> {:error, :boom} end) == {:error, :boom}
    end

    test "returns an error with no change and does not call the function" do
      assert then_ok({:error, :fail}, fn _ -> raise "then_ok must not call this function" end) ==
               {:error, :fail}
    end

    test "returns a bare :ok with no change" do
      assert then_ok(:ok, fn _ -> {:ok, 42} end) == :ok
    end

    test "returns a bare :error with no change" do
      assert then_ok(:error, fn _ -> raise "then_ok must not call this function" end) == :error
    end

    test "does not enforce the return type of the function" do
      # The function must return a result tuple, but Shoddy.Result does not
      # enforce that.
      assert then_ok({:ok, 1}, fn x -> x + 1 end) == 2
    end

    test "chains two operations that can fail" do
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

  describe "recover/2" do
    test "calls the function with an error tuple as it is" do
      assert recover({:error, :miss}, fn error -> {:ok, error} end) == {:ok, {:error, :miss}}
    end

    test "calls the function with a bare :error as it is" do
      assert recover(:error, fn error -> {:ok, error} end) == {:ok, :error}
    end

    test "keeps the shape of an error that the function returns with no change" do
      pass_through = fn
        {:error, :miss} -> {:ok, :default}
        error -> error
      end

      assert recover(:error, pass_through) == :error
      assert recover({:error, :other}, pass_through) == {:error, :other}
    end

    test "returns the result of the function with no change" do
      assert recover({:error, :miss}, fn _error -> {:error, :other} end) == {:error, :other}
      assert recover({:error, :miss}, fn _error -> :ok end) == :ok
    end

    test "returns an ok result with no change and does not call the function" do
      on_error = fn _error -> send(self(), :called) end

      assert recover({:ok, 1}, on_error) == {:ok, 1}
      assert recover(:ok, on_error) == :ok
      refute_received :called
    end

    test "raises FunctionClauseError for a function that is not of arity 1" do
      assert_raise FunctionClauseError, fn -> apply(&recover/2, [{:error, :miss}, fn -> {:ok, 1} end]) end
    end
  end

  describe "unwrap!/1" do
    test "extracts the value from an ok tuple" do
      assert unwrap!({:ok, 42}) == 42
    end

    test "extracts nil from {:ok, nil}" do
      assert unwrap!({:ok, nil}) == nil
    end

    test "returns nil for a bare :ok" do
      assert unwrap!(:ok) == nil
    end

    test "raises ArgumentError for an error tuple" do
      assert_raise ArgumentError, ~r/unwrap! called on error result: :fail/, fn ->
        unwrap!({:error, :fail})
      end
    end

    test "raises ArgumentError for a bare :error" do
      assert_raise ArgumentError, ~r/unwrap! called on error result: nil/, fn ->
        unwrap!(:error)
      end
    end
  end

  describe "unwrap/2" do
    test "extracts the value from an ok tuple" do
      assert unwrap({:ok, 42}, 0) == 42
    end

    test "returns the default for an error tuple" do
      assert unwrap({:error, :fail}, 0) == 0
    end

    test "returns nil for {:ok, nil}, and not the default" do
      assert unwrap({:ok, nil}, :default) == nil
    end

    test "returns nil for a bare :ok" do
      assert unwrap(:ok, 0) == nil
    end

    test "returns the default for a bare :error" do
      assert unwrap(:error, 0) == 0
    end
  end

  # Conversion helpers

  describe "flatten/1" do
    test "flattens an ok tuple that contains an ok tuple" do
      assert flatten({:ok, {:ok, 42}}) == {:ok, 42}
    end

    test "flattens an ok tuple that contains an error tuple" do
      assert flatten({:ok, {:error, :fail}}) == {:error, :fail}
    end

    test "flattens an ok tuple that contains a bare :ok" do
      assert flatten({:ok, :ok}) == :ok
    end

    test "flattens an ok tuple that contains a bare :error" do
      assert flatten({:ok, :error}) == :error
    end

    test "flattens one level only" do
      assert flatten({:ok, {:ok, {:ok, 42}}}) == {:ok, {:ok, 42}}
    end

    test "does not change an ok tuple that contains no result" do
      assert flatten({:ok, 42}) == {:ok, 42}
    end

    test "does not change an error" do
      assert flatten({:error, :fail}) == {:error, :fail}
    end

    test "returns a bare :ok with no change" do
      assert flatten(:ok) == :ok
    end

    test "returns a bare :error with no change" do
      assert flatten(:error) == :error
    end

    test "returns a value that is not a result with no change" do
      assert flatten(42) == 42
      assert flatten(:something) == :something
    end
  end

  describe "from_nil/2" do
    test "puts a value that is not nil into an ok tuple" do
      assert from_nil(42, :not_found) == {:ok, 42}
    end

    test "converts nil into an error tuple" do
      assert from_nil(nil, :not_found) == {:error, :not_found}
    end

    test "accepts false as a value that is not nil" do
      assert from_nil(false, :not_found) == {:ok, false}
    end

    test "accepts nil as the error reason" do
      assert from_nil(nil, nil) == {:error, nil}
    end

    test "operates together with Map.get" do
      assert Map.get(%{a: 1}, :b) |> from_nil(:missing) == {:error, :missing}
      assert Map.get(%{a: 1}, :a) |> from_nil(:missing) == {:ok, 1}
    end
  end

  describe "ensure/3" do
    test "returns an ok tuple if the predicate returns a truthy value" do
      assert ensure(36, &(&1 >= 18), :too_young) == {:ok, 36}
      assert ensure(36, fn _ -> :yes end, :too_young) == {:ok, 36}
    end

    test "returns an error tuple if the predicate returns nil or false" do
      assert ensure(12, &(&1 >= 18), :too_young) == {:error, :too_young}
      assert ensure(12, fn _ -> nil end, :too_young) == {:error, :too_young}
    end

    test "accepts a predicate of arity 0" do
      assert ensure(:delete, fn -> true end, :forbidden) == {:ok, :delete}
      assert ensure(:delete, fn -> false end, :forbidden) == {:error, :forbidden}
    end

    test "accepts nil and a result as the value" do
      assert ensure(nil, &is_nil/1, :present) == {:ok, nil}
      assert ensure({:error, :x}, fn _ -> true end, :unused) == {:ok, {:error, :x}}
    end

    test "raises FunctionClauseError for a predicate of another arity" do
      assert_raise FunctionClauseError, fn -> apply(&ensure/3, [1, fn _, _ -> true end, :r]) end
    end
  end

  describe "ignore/1" do
    test "discards the value from an ok tuple" do
      assert ignore({:ok, 42}) == :ok
    end

    test "returns a bare :ok with no change" do
      assert ignore(:ok) == :ok
    end

    test "returns an error tuple with no change" do
      assert ignore({:error, :fail}) == {:error, :fail}
    end

    test "returns a bare :error with no change" do
      assert ignore(:error) == :error
    end
  end

  describe "tap_ok/2" do
    test "calls the function for its side effect and returns the result" do
      assert tap_ok({:ok, 42}, fn val -> send(self(), {:got, val}) end) == {:ok, 42}
      assert_received {:got, 42}
    end

    test "does not call the function for an error" do
      assert tap_ok({:error, :fail}, fn _ -> send(self(), :called) end) == {:error, :fail}
      refute_received :called
    end

    test "returns a bare :ok and does not call the function" do
      assert tap_ok(:ok, fn _ -> send(self(), :called) end) == :ok
      refute_received :called
    end

    test "returns a bare :error and does not call the function" do
      assert tap_ok(:error, fn _ -> send(self(), :called) end) == :error
      refute_received :called
    end
  end

  describe "tap_error/2" do
    test "calls the function for its side effect and returns the result" do
      assert tap_error({:error, :fail}, fn reason -> send(self(), {:err, reason}) end) ==
               {:error, :fail}

      assert_received {:err, :fail}
    end

    test "does not call the function for an ok result" do
      assert tap_error({:ok, 42}, fn _ -> send(self(), :called) end) == {:ok, 42}
      refute_received :called
    end

    test "returns a bare :error and does not call the function" do
      assert tap_error(:error, fn _ -> send(self(), :called) end) == :error
      refute_received :called
    end

    test "returns a bare :ok and does not call the function" do
      assert tap_error(:ok, fn _ -> send(self(), :called) end) == :ok
      refute_received :called
    end
  end

  # Lists of results

  describe "collect/1" do
    test "returns an empty list in an ok tuple for an empty list" do
      assert collect([]) == {:ok, []}
    end

    test "returns the values in the order of the input" do
      assert collect([{:ok, 3}, {:ok, 1}, {:ok, 2}]) == {:ok, [3, 1, 2]}
    end

    test "puts nil into the list for a bare :ok" do
      assert collect([:ok, {:ok, 1}]) == {:ok, [nil, 1]}
    end

    test "returns the first error tuple with no change" do
      assert collect([{:ok, 1}, {:error, :first}, {:error, :second}]) == {:error, :first}
    end

    test "returns a bare :error with no change" do
      assert collect([{:ok, 1}, :error, {:error, :second}]) == :error
    end

    test "does not examine an element after the first error" do
      assert apply(&collect/1, [[{:error, :first}, 42]]) == {:error, :first}
    end

    test "raises FunctionClauseError for an element that is not a result" do
      assert_raise FunctionClauseError, fn -> apply(&collect/1, [[{:ok, 1}, 42]]) end
    end

    test "accepts a stream" do
      assert collect(Stream.map([1, 2], &{:ok, &1})) == {:ok, [1, 2]}
      assert collect(Stream.map([1, 2], &{:error, &1})) == {:error, 1}
    end

    test "accepts a stream that is a function" do
      assert collect(Stream.repeatedly(fn -> {:error, :bad} end)) == {:error, :bad}

      assert collect(
               Stream.unfold(3, fn
                 0 -> nil
                 n -> {{:ok, n}, n - 1}
               end)
             ) == {:ok, [3, 2, 1]}
    end

    test "accepts another struct that implements Enumerable" do
      assert collect(MapSet.new([{:ok, 1}])) == {:ok, [1]}
    end

    test "reads no element of a stream after the first error" do
      results =
        Stream.map([{:ok, 1}, {:error, :bad}, :boom], fn
          :boom -> flunk("the stream computed an element after the first error")
          result -> result
        end)

      assert collect(results) == {:error, :bad}
    end

    test "stops at the first error of an infinite stream" do
      results = Stream.concat([{:ok, 1}, {:error, :bad}], Stream.repeatedly(fn -> {:ok, 0} end))

      assert collect(results) == {:error, :bad}
    end

    test "raises FunctionClauseError for an argument that is not a list, a stream or a struct" do
      assert_raise FunctionClauseError, fn -> apply(&collect/1, [{:ok, 1}]) end
      assert_raise FunctionClauseError, fn -> apply(&collect/1, [42]) end
      assert_raise FunctionClauseError, fn -> apply(&collect/1, [nil]) end
      assert_raise FunctionClauseError, fn -> apply(&collect/1, [fn x -> x end]) end
    end

    test "raises FunctionClauseError for a map" do
      assert_raise FunctionClauseError, fn -> apply(&collect/1, [%{ok: 1}]) end
    end
  end

  describe "collect/2 with the option :on_error" do
    @results [{:ok, 1}, {:error, :first}, :ok, :error, {:ok, 5}]

    test ":halt returns the first error, as the default does" do
      assert collect(@results, on_error: :halt) == {:error, :first}
      assert collect(@results, on_error: :halt) == collect(@results)
    end

    test ":skip returns the values of the ok elements" do
      assert collect(@results, on_error: :skip) == {:ok, [1, nil, 5]}
    end

    test ":skip returns an empty list in an ok tuple if each element is an error" do
      assert collect([:error, {:error, :x}], on_error: :skip) == {:ok, []}
    end

    test ":accumulate returns the reason of each error, and nil for a bare :error" do
      assert collect(@results, on_error: :accumulate) == {:error, [:first, nil]}
    end

    test ":accumulate returns the values if there is no error" do
      assert collect([{:ok, 1}, :ok], on_error: :accumulate) == {:ok, [1, nil]}
    end

    test ":accumulate examines each element, also after an error" do
      assert_raise FunctionClauseError, fn ->
        apply(&collect/2, [[{:error, :first}, 42], [on_error: :accumulate]])
      end
    end

    test "a function receives each error with no change" do
      on_error = fn error ->
        send(self(), {:received, error})
        :skip
      end

      collect(@results, on_error: on_error)

      assert_received {:received, {:error, :first}}
      assert_received {:received, :error}
    end

    test "a function can put a value into the list for an error" do
      assert collect(@results, on_error: fn _error -> {:cont, 0} end) == {:ok, [1, 0, nil, 0, 5]}
    end

    test "a function can skip an error" do
      assert collect(@results, on_error: fn _error -> :skip end) == {:ok, [1, nil, 5]}
    end

    test "a function can stop the list with a different error" do
      assert collect(@results, on_error: fn _error -> {:halt, {:error, :changed}} end) ==
               {:error, :changed}
    end

    test "a function can stop the list with a bare :error" do
      assert collect(@results, on_error: fn _error -> {:halt, :error} end) == :error
    end

    test "a function is not called after it stops the list" do
      on_error = fn error ->
        send(self(), {:received, error})
        {:halt, error}
      end

      collect(@results, on_error: on_error)

      assert_received {:received, {:error, :first}}
      refute_received {:received, :error}
    end

    test "raises ArgumentError if the function stops the list with a value that is not an error" do
      assert_raise ArgumentError, ~r/invalid return value of the :on_error function/, fn ->
        collect(@results, on_error: fn _error -> {:halt, {:ok, 1}} end)
      end
    end

    test "raises ArgumentError if the function returns an unknown value" do
      assert_raise ArgumentError, ~r/invalid return value of the :on_error function/, fn ->
        collect(@results, on_error: fn _error -> :ignore end)
      end
    end

    test "raises ArgumentError for an unknown value of the option" do
      assert_raise ArgumentError, ~r/invalid value for :on_error option/, fn ->
        collect(@results, on_error: :continue)
      end
    end

    test "raises ArgumentError for a function of the wrong arity" do
      assert_raise ArgumentError, ~r/invalid value for :on_error option/, fn ->
        collect(@results, on_error: fn -> :skip end)
      end
    end

    test "raises ArgumentError for an unknown option" do
      assert_raise ArgumentError, fn -> collect(@results, on_errors: :skip) end
    end
  end

  # The moduledoc states that most functions raise FunctionClauseError for an
  # input that is not a result. The tests below examine that rule. Without
  # them, no test fails if a change adds a clause that accepts every input.
  #
  # Each test below calls a function through apply/2. The compiler examines
  # the type of each argument at a direct call. It reports a type violation
  # for an argument that no clause of the function accepts. Each test here
  # must pass such an argument, because each test examines the behaviour at
  # run time. The compiler does not examine the arguments of apply/2, and it
  # thus reports no violation. The capture of the function lets the compiler
  # check that the function exists with that arity.
  describe "the contract for an input that is not a result" do
    test "map_ok/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&map_ok/2, [42, &Function.identity/1]) end
    end

    test "map_error/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&map_error/2, [42, &Function.identity/1]) end
    end

    test "then_ok/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&then_ok/2, [42, &{:ok, &1}]) end
    end

    test "unwrap!/1 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&unwrap!/1, [42]) end
    end

    test "unwrap/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&unwrap/2, [42, :default]) end
    end

    test "ignore/1 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&ignore/1, [42]) end
    end

    test "tap_ok/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&tap_ok/2, [42, &Function.identity/1]) end
    end

    test "tap_error/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&tap_error/2, [42, &Function.identity/1]) end
    end

    test "recover/2 raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> apply(&recover/2, [42, &{:ok, &1}]) end
    end
  end
end
