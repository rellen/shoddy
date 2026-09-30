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

  describe "put_present/3" do
    test "puts a value that is not nil" do
      assert put_present(%{a: 1}, :b, 2) == %{a: 1, b: 2}
    end

    test "puts false" do
      assert put_present(%{}, :subscribed, false) == %{subscribed: false}
    end

    test "ignores nil" do
      assert put_present(%{a: 1}, :b, nil) == %{a: 1}
    end

    test "replaces an entry that is already in the map with a value that is not nil" do
      assert put_present(%{a: 1}, :a, false) == %{a: false}
    end

    test "does not change an entry that is already in the map if the value is nil" do
      assert put_present(%{a: 1}, :a, nil) == %{a: 1}
    end

    test "raises FunctionClauseError for a first argument that is not a map" do
      assert_raise FunctionClauseError, fn -> apply(&put_present/3, [[a: 1], :b, 2]) end
    end
  end

  describe "a struct as the first argument" do
    for function <- [:put_if, :put_present] do
      test "#{function}/3 puts a value into a field of the struct" do
        uri = %URI{host: "example.com"}
        assert apply(Shoddy.Maps, unquote(function), [uri, :port, 443]) == %{uri | port: 443}
      end

      test "#{function}/3 raises KeyError for a key that is not a field" do
        assert_raise KeyError, ~r/key :hots not found/, fn ->
          apply(Shoddy.Maps, unquote(function), [%URI{}, :hots, "example.com"])
        end
      end

      test "#{function}/3 raises KeyError for a key that is not a field, also for nil" do
        assert_raise KeyError, fn -> apply(Shoddy.Maps, unquote(function), [%URI{}, :hots, nil]) end
      end
    end

    test "put_if/3 raises KeyError for a key that is not a field, also for false" do
      assert_raise KeyError, fn -> put_if(%URI{}, :hots, false) end
    end

    test "put_if/3 does not change a field for a falsy value" do
      uri = %URI{host: "example.com"}
      assert put_if(uri, :host, nil) == uri
    end

    test "put_present/3 puts false into a field" do
      assert put_present(%URI{}, :port, false).port == false
    end
  end
end
