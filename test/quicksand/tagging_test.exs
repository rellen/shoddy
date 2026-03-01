defmodule Quicksand.TaggingTest do
  use ExUnit.Case, async: true

  doctest Quicksand.Tagging

  describe "ok/1" do
    test "wraps a value in an :ok tuple" do
      assert Quicksand.Tagging.ok(42) == {:ok, 42}
    end

    test "wraps nil" do
      assert Quicksand.Tagging.ok(nil) == {:ok, nil}
    end

    test "wraps complex data structures" do
      assert Quicksand.Tagging.ok(%{a: 1}) == {:ok, %{a: 1}}
    end
  end

  describe "error/1" do
    test "wraps a value in an :error tuple" do
      assert Quicksand.Tagging.error("reason") == {:error, "reason"}
    end

    test "wraps an atom reason" do
      assert Quicksand.Tagging.error(:not_found) == {:error, :not_found}
    end
  end

  describe "noreply/1" do
    test "wraps a value in a :noreply tuple" do
      assert Quicksand.Tagging.noreply(%{state: :ready}) == {:noreply, %{state: :ready}}
    end
  end

  describe "noreply/2" do
    test "wraps state and timeout in a :noreply 3-tuple" do
      assert Quicksand.Tagging.noreply(%{count: 0}, 5000) == {:noreply, %{count: 0}, 5000}
    end

    test "wraps state and :hibernate" do
      assert Quicksand.Tagging.noreply(%{}, :hibernate) == {:noreply, %{}, :hibernate}
    end
  end

  describe "cont/1" do
    test "wraps a value in a :cont tuple" do
      assert Quicksand.Tagging.cont(0) == {:cont, 0}
    end
  end

  describe "halt/1" do
    test "wraps a value in a :halt tuple" do
      assert Quicksand.Tagging.halt(42) == {:halt, 42}
    end
  end

  describe "reply/1" do
    test "wraps a value in a :reply tuple" do
      assert Quicksand.Tagging.reply("hello") == {:reply, "hello"}
    end
  end

  describe "reply/2" do
    test "wraps reply and state in a :reply 3-tuple" do
      assert Quicksand.Tagging.reply(:ok, %{count: 1}) == {:reply, :ok, %{count: 1}}
    end
  end

  describe "stop/1" do
    test "wraps a value in a :stop tuple" do
      assert Quicksand.Tagging.stop(:normal) == {:stop, :normal}
    end
  end

  describe "stop/2" do
    test "wraps reason and state in a :stop 3-tuple" do
      assert Quicksand.Tagging.stop(:normal, %{}) == {:stop, :normal, %{}}
    end
  end

  describe "tag/2" do
    test "wraps a value with a custom atom tag" do
      assert Quicksand.Tagging.tag("hello", :reply) == {:reply, "hello"}
    end

    test "raises FunctionClauseError for non-atom tag" do
      assert_raise FunctionClauseError, fn ->
        Quicksand.Tagging.tag(42, "not_an_atom")
      end
    end
  end

  describe "tag/3" do
    test "wraps two values with a custom atom tag" do
      assert Quicksand.Tagging.tag(:ok, %{count: 1}, :reply) == {:reply, :ok, %{count: 1}}
    end

    test "raises FunctionClauseError for non-atom tag" do
      assert_raise FunctionClauseError, fn ->
        Quicksand.Tagging.tag(:ok, %{}, "not_an_atom")
      end
    end
  end
end
