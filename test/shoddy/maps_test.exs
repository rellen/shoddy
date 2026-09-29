defmodule Shoddy.MapsTest do
  use ExUnit.Case, async: true

  import Shoddy.Maps

  doctest Shoddy.Maps

  describe "put_if/3" do
    test "puts a truthy value into an empty map" do
      assert put_if(%{}, :name, "Ada") == %{name: "Ada"}
    end

    test "puts a truthy value into a map that has entries" do
      assert put_if(%{a: 1}, :b, 2) == %{a: 1, b: 2}
    end

    test "ignores nil" do
      assert put_if(%{a: 1}, :b, nil) == %{a: 1}
    end

    test "ignores false" do
      assert put_if(%{a: 1}, :b, false) == %{a: 1}
    end

    test "replaces an entry that is already in the map with a truthy value" do
      assert put_if(%{a: 1}, :a, 2) == %{a: 2}
    end

    test "does not change an entry that is already in the map if the value is falsy" do
      assert put_if(%{a: 1}, :a, nil) == %{a: 1}
      assert put_if(%{a: 1}, :a, false) == %{a: 1}
    end

    test "puts zero, which is truthy in Elixir" do
      assert put_if(%{}, :count, 0) == %{count: 0}
    end

    test "puts an empty collection, which is truthy in Elixir" do
      assert put_if(%{}, :items, []) == %{items: []}
      assert put_if(%{}, :name, "") == %{name: ""}
      assert put_if(%{}, :meta, %{}) == %{meta: %{}}
    end

    test "puts true" do
      assert put_if(%{}, :admin?, true) == %{admin?: true}
    end

    test "accepts a key that is not an atom" do
      assert put_if(%{}, "name", "Ada") == %{"name" => "Ada"}
      assert put_if(%{}, {:composite, 1}, :val) == %{{:composite, 1} => :val}
      assert put_if(%{}, "name", nil) == %{}
    end

    test "chains in a pipeline and omits the falsy fields" do
      result =
        %{}
        |> put_if(:name, "Ada")
        |> put_if(:email, nil)
        |> put_if(:admin?, false)
        |> put_if(:age, 36)

      assert result == %{name: "Ada", age: 36}
    end

    test "raises FunctionClauseError for a first argument that is not a map" do
      assert_raise FunctionClauseError, fn -> put_if([a: 1], :b, 2) end
      assert_raise FunctionClauseError, fn -> put_if(nil, :b, 2) end
    end
  end
end
