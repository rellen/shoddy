defmodule Quicksand.TaggingTest do
  use ExUnit.Case, async: true

  import Quicksand.Tagging

  doctest Quicksand.Tagging

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

  describe "error/1" do
    test "puts a value into an :error tuple" do
      assert error("reason") == {:error, "reason"}
    end

    test "puts an atom reason into an :error tuple" do
      assert error(:not_found) == {:error, :not_found}
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
        tag(42, "not_an_atom")
      end
    end
  end

  describe "tag/3" do
    test "puts two values into a tuple with a custom atom tag" do
      assert tag(:ok, %{count: 1}, :reply) == {:reply, :ok, %{count: 1}}
    end

    test "raises FunctionClauseError for a tag that is not an atom" do
      assert_raise FunctionClauseError, fn ->
        tag(:ok, %{}, "not_an_atom")
      end
    end
  end
end
