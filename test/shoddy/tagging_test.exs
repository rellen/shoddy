defmodule Shoddy.TaggingTest do
  use ExUnit.Case, async: true

  import Shoddy.Tagging

  doctest Shoddy.Tagging

  describe "ok/1" do
    test "puts a value into an :ok tuple" do
      assert ok(42) == {:ok, 42}
    end

    test "puts nil into an :ok tuple" do
      assert ok(nil) == {:ok, nil}
    end

    test "puts a complex data structure into an :ok tuple" do
      assert ok(%{a: 1}) == {:ok, %{a: 1}}
    end
  end

  describe "ok/2" do
    test "puts a value and a second value into an :ok tagged tuple of three elements" do
      assert ok(:priority, 3) == {:ok, :priority, 3}
    end

    test "takes the value from a pipeline" do
      assert 42 |> ok(" apples") == {:ok, 42, " apples"}
    end

    test "accepts nil for each argument" do
      assert ok(nil, nil) == {:ok, nil, nil}
    end
  end

  describe "error/1" do
    test "puts a value into an :error tuple" do
      assert error("reason") == {:error, "reason"}
    end

    test "puts an atom reason into an :error tuple" do
      assert error(:not_found) == {:error, :not_found}
    end
  end

  describe "error/2" do
    test "puts a reason and a second value into an :error tagged tuple of three elements" do
      assert error(:unterminated, ["a", "b"]) == {:error, :unterminated, ["a", "b"]}
    end

    test "takes the reason from a pipeline" do
      assert :timeout |> error(%{attempts: 3}) == {:error, :timeout, %{attempts: 3}}
    end
  end

  describe "noreply/1" do
    test "puts a value into a :noreply tuple" do
      assert noreply(%{state: :ready}) == {:noreply, %{state: :ready}}
    end
  end

  describe "noreply/2" do
    test "puts a state and a timeout into a :noreply tagged tuple of three elements" do
      assert noreply(%{count: 0}, 5000) == {:noreply, %{count: 0}, 5000}
    end

    test "puts a state and :hibernate into a :noreply tagged tuple of three elements" do
      assert noreply(%{}, :hibernate) == {:noreply, %{}, :hibernate}
    end
  end

  describe "cont/1" do
    test "puts a value into a :cont tuple" do
      assert cont(0) == {:cont, 0}
    end
  end

  describe "halt/1" do
    test "puts a value into a :halt tuple" do
      assert halt(42) == {:halt, 42}
    end
  end

  describe "reply/1" do
    test "puts a value into a :reply tuple" do
      assert reply("hello") == {:reply, "hello"}
    end
  end

  describe "reply/2" do
    test "puts a reply and a state into a :reply tagged tuple of three elements" do
      assert reply(:ok, %{count: 1}) == {:reply, :ok, %{count: 1}}
    end
  end

  describe "reply_with/2" do
    test "puts a state and a reply into a :reply tagged tuple, with the reply before the state" do
      assert reply_with(%{count: 1}, :ok) == {:reply, :ok, %{count: 1}}
    end

    test "takes the state from a pipeline" do
      assert %{count: 1} |> Map.put(:count, 2) |> reply_with(:ok) == {:reply, :ok, %{count: 2}}
    end

    test "returns the same tuple as reply/2 with the arguments in the other order" do
      assert reply_with(:state, :reply) == reply(:reply, :state)
    end
  end

  describe "stop/1" do
    test "puts a value into a :stop tuple" do
      assert stop(:normal) == {:stop, :normal}
    end
  end

  describe "stop/2" do
    test "puts a reason and a state into a :stop tagged tuple of three elements" do
      assert stop(:normal, %{}) == {:stop, :normal, %{}}
    end
  end

  describe "stop_with/2" do
    test "puts a state and a reason into a :stop tagged tuple, with the reason before the state" do
      assert stop_with(%{count: 1}, :normal) == {:stop, :normal, %{count: 1}}
    end

    test "takes the state from a pipeline" do
      assert %{count: 1} |> Map.put(:count, 2) |> stop_with(:shutdown) == {:stop, :shutdown, %{count: 2}}
    end

    test "returns the same tuple as stop/2 with the arguments in the other order" do
      assert stop_with(:state, :reason) == stop(:reason, :state)
    end
  end

  describe "tag/2" do
    test "puts a value into a tuple with a custom atom tag" do
      assert tag("hello", :reply) == {:reply, "hello"}
    end

    test "operates in a pipeline" do
      assert 42 |> tag(:ok) == {:ok, 42}
    end

    test "accepts nil as a tag" do
      assert tag(42, nil) == {nil, 42}
    end

    test "accepts a boolean as a tag" do
      assert tag(42, true) == {true, 42}
      assert tag(42, false) == {false, 42}
    end

    test "raises FunctionClauseError for a tag that is not an atom" do
      assert_raise FunctionClauseError, fn ->
        apply(&tag/2, [42, "not_an_atom"])
      end
    end
  end

  describe "tag/3" do
    test "puts two values into a tuple with a custom atom tag" do
      assert tag(:ok, %{count: 1}, :reply) == {:reply, :ok, %{count: 1}}
    end

    test "raises FunctionClauseError for a tag that is not an atom" do
      assert_raise FunctionClauseError, fn ->
        apply(&tag/3, [:ok, %{}, "not_an_atom"])
      end
    end
  end
end
