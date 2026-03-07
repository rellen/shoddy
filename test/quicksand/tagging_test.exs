defmodule Quicksand.TaggingTest do
  use ExUnit.Case, async: true

  import Quicksand.Tagging

  doctest Quicksand.Tagging

  describe "ok/1" do
    test "wraps a value in an :ok tuple" do
      assert ok(42) == {:ok, 42}
    end

    test "wraps nil" do
      assert ok(nil) == {:ok, nil}
    end

    test "wraps complex data structures" do
      assert ok(%{a: 1}) == {:ok, %{a: 1}}
    end
  end

  describe "error/1" do
    test "wraps a value in an :error tuple" do
      assert error("reason") == {:error, "reason"}
    end

    test "wraps an atom reason" do
      assert error(:not_found) == {:error, :not_found}
    end
  end

  describe "noreply/1" do
    test "wraps a value in a :noreply tuple" do
      assert noreply(%{state: :ready}) == {:noreply, %{state: :ready}}
    end
  end

  describe "noreply/2" do
    test "wraps state and timeout in a :noreply 3-tuple" do
      assert noreply(%{count: 0}, 5000) == {:noreply, %{count: 0}, 5000}
    end

    test "wraps state and :hibernate" do
      assert noreply(%{}, :hibernate) == {:noreply, %{}, :hibernate}
    end
  end

  describe "cont/1" do
    test "wraps a value in a :cont tuple" do
      assert cont(0) == {:cont, 0}
    end
  end

  describe "halt/1" do
    test "wraps a value in a :halt tuple" do
      assert halt(42) == {:halt, 42}
    end
  end

  describe "reply/1" do
    test "wraps a value in a :reply tuple" do
      assert reply("hello") == {:reply, "hello"}
    end
  end

  describe "reply/2" do
    test "wraps reply and state in a :reply 3-tuple" do
      assert reply(:ok, %{count: 1}) == {:reply, :ok, %{count: 1}}
    end
  end

  describe "stop/1" do
    test "wraps a value in a :stop tuple" do
      assert stop(:normal) == {:stop, :normal}
    end
  end

  describe "stop/2" do
    test "wraps reason and state in a :stop 3-tuple" do
      assert stop(:normal, %{}) == {:stop, :normal, %{}}
    end
  end

  describe "tag/2" do
    test "wraps a value with a custom atom tag" do
      assert tag("hello", :reply) == {:reply, "hello"}
    end

    test "works in pipelines" do
      assert 42 |> tag(:ok) == {:ok, 42}
    end

    test "accepts nil as a tag" do
      assert tag(42, nil) == {nil, 42}
    end

    test "accepts booleans as tags" do
      assert tag(42, true) == {true, 42}
      assert tag(42, false) == {false, 42}
    end

    test "raises FunctionClauseError for non-atom tag" do
      assert_raise FunctionClauseError, fn ->
        tag(42, "not_an_atom")
      end
    end
  end

  describe "tag/3" do
    test "wraps two values with a custom atom tag" do
      assert tag(:ok, %{count: 1}, :reply) == {:reply, :ok, %{count: 1}}
    end

    test "raises FunctionClauseError for non-atom tag" do
      assert_raise FunctionClauseError, fn ->
        tag(:ok, %{}, "not_an_atom")
      end
    end
  end
end
