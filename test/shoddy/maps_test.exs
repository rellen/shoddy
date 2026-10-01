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

  describe "take_as/2" do
    test "takes each key of the mapping and gives it the new name" do
      assert take_as(%{"a" => 1, "b" => 2, "c" => 3}, %{"a" => :x, "b" => :y}) == %{x: 1, y: 2}
    end

    test "skips a key that is not in the map" do
      assert take_as(%{"a" => 1}, %{"a" => :x, "b" => :y}) == %{x: 1}
    end

    test "keeps a key with the value nil or false" do
      assert take_as(%{"a" => nil, "b" => false}, %{"a" => :x, "b" => :y}) == %{x: nil, y: false}
    end

    test "returns an empty map for an empty mapping" do
      assert take_as(%{"a" => 1}, %{}) == %{}
    end

    test "accepts a new name that is the same as the key" do
      assert take_as(%{a: 1, b: 2}, %{a: :a}) == %{a: 1}
    end

    test "returns a plain map for a struct" do
      result = take_as(%URI{host: "example.com"}, %{host: :host})

      assert result == %{host: "example.com"}
      refute is_struct(result)
    end

    test "raises ArgumentError if two keys have the same new name" do
      assert_raise ArgumentError, ~r/same new name: :x for the keys \["a", "b"\]$/, fn ->
        take_as(%{"a" => 1}, %{"a" => :x, "b" => :x})
      end
    end

    test "names each shared new name and all its keys in the error message" do
      message = ~r/same new name: :x for the keys \["a", "b", "c"\]; :y for the keys \["d", "e"\]$/

      assert_raise ArgumentError, message, fn ->
        take_as(%{}, %{"e" => :y, "a" => :x, "b" => :x, "c" => :x, "d" => :y, "f" => :z})
      end
    end

    test "raises ArgumentError for the new name :__struct__" do
      assert_raise ArgumentError, ~r/cannot be :__struct__/, fn ->
        take_as(%{"t" => Date, "y" => 2000}, %{"t" => :__struct__, "y" => :year})
      end
    end

    test "raises FunctionClauseError for a mapping that is a struct" do
      assert_raise FunctionClauseError, fn -> apply(&take_as/2, [%{a: 1}, %URI{}]) end

      assert_raise FunctionClauseError, fn ->
        apply(&take_as/2, [%{host: "h"}, %{__struct__: :__struct__, host: :host}])
      end
    end

    test "raises FunctionClauseError for a mapping that is not a map" do
      assert_raise FunctionClauseError, fn -> apply(&take_as/2, [%{"a" => 1}, [{"a", :x}]]) end
    end

    test "raises FunctionClauseError for a first argument that is not a map" do
      assert_raise FunctionClauseError, fn -> apply(&take_as/2, [[a: 1], %{a: :x}]) end
    end
  end

  describe "deep_merge/2" do
    test "merges the nested maps of a key at each level" do
      left = %{a: %{b: %{c: 1, d: 2}, e: 3}, f: 4}
      right = %{a: %{b: %{c: 10}, g: 5}}

      assert deep_merge(left, right) == %{a: %{b: %{c: 10, d: 2}, e: 3, g: 5}, f: 4}
    end

    test "keeps each key that only one map has" do
      assert deep_merge(%{a: 1}, %{b: 2}) == %{a: 1, b: 2}
    end

    test "returns the other map if one map is empty" do
      assert deep_merge(%{}, %{a: %{b: 1}}) == %{a: %{b: 1}}
      assert deep_merge(%{a: %{b: 1}}, %{}) == %{a: %{b: 1}}
    end

    test "keeps the nested map of the left map for an empty map in the right map" do
      assert deep_merge(%{a: %{b: 1}}, %{a: %{}}) == %{a: %{b: 1}}
    end

    test "replaces a value with nil or false from the right map" do
      assert deep_merge(%{a: %{b: 1}}, %{a: nil}) == %{a: nil}
      assert deep_merge(%{a: 1}, %{a: false}) == %{a: false}
    end

    test "replaces a value that is not a map with a map, and a map with a value that is not a map" do
      assert deep_merge(%{a: 1}, %{a: %{b: 2}}) == %{a: %{b: 2}}
      assert deep_merge(%{a: %{b: 2}}, %{a: [b: 3]}) == %{a: [b: 3]}
    end

    test "replaces a list and a keyword list, and does not join them" do
      assert deep_merge(%{a: [1, 2], b: [x: 1]}, %{a: [3], b: [y: 2]}) == %{a: [3], b: [y: 2]}
    end

    test "replaces a struct, and does not merge its fields" do
      left = %{uri: %URI{host: "example.com", port: 443}}
      right = %{uri: %URI{host: "example.org"}}

      assert deep_merge(left, right) == right
    end

    test "replaces a struct with a plain map, and a plain map with a struct" do
      assert deep_merge(%{a: %URI{port: 443}}, %{a: %{port: 80}}) == %{a: %{port: 80}}
      assert deep_merge(%{a: %{port: 80}}, %{a: %URI{port: 443}}) == %{a: %URI{port: 443}}
    end

    test "keeps the left key and the right key of 1 and 1.0 as two keys" do
      assert deep_merge(%{1 => %{a: 1}}, %{1.0 => %{b: 2}}) == %{1 => %{a: 1}, 1.0 => %{b: 2}}
    end

    test "raises FunctionClauseError for a struct as an argument" do
      assert_raise FunctionClauseError, fn -> apply(&deep_merge/2, [%URI{}, %{port: 80}]) end
      assert_raise FunctionClauseError, fn -> apply(&deep_merge/2, [%{port: 80}, %URI{}]) end
    end

    test "raises FunctionClauseError for an argument that is not a map" do
      assert_raise FunctionClauseError, fn -> apply(&deep_merge/2, [[a: 1], %{a: 2}]) end
      assert_raise FunctionClauseError, fn -> apply(&deep_merge/2, [%{a: 1}, nil]) end
    end
  end
end
