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

  describe "get_present/3" do
    test "returns the value of the key" do
      assert get_present(%{"a" => 1}, "a", 0) == 1
    end

    test "returns the default for an absent key and for nil" do
      assert get_present(%{}, :a, 0) == 0
      assert get_present(%{a: nil}, :a, 0) == 0
    end

    test "returns false, zero and an empty string with no change" do
      assert get_present(%{a: false}, :a, true) == false
      assert get_present(%{a: 0}, :a, 1) == 0
      assert get_present(%{a: ""}, :a, "x") == ""
    end

    test "compares the key with the strict equality operator" do
      assert get_present(%{1 => :int}, 1.0, :default) == :default
    end

    test "accepts nil as a key" do
      assert get_present(%{nil => :value}, nil, :default) == :value
    end

    test "reads a field of a struct, and returns the default for a key that is not a field" do
      assert get_present(%URI{host: "example.com"}, :host, "x") == "example.com"
      assert get_present(%URI{}, :nope, "x") == "x"
    end

    test "raises FunctionClauseError for a first argument that is not a map" do
      assert_raise FunctionClauseError, fn -> apply(&get_present/3, [[a: 1], :a, 0]) end
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

      test "#{function}/3 raises KeyError for the key :__struct__, also for nil" do
        for value <- [Date, nil] do
          assert_raise KeyError, "the key :__struct__ is not a field of the struct URI", fn ->
            apply(Shoddy.Maps, unquote(function), [%URI{}, :__struct__, value])
          end
        end
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

  describe "map_values/2" do
    test "applies the function to each value and keeps the keys" do
      assert map_values(%{"a" => 1, nil => 2}, &to_string/1) == %{"a" => "1", nil => "2"}
    end

    test "keeps a nil result" do
      assert map_values(%{a: 1}, fn _ -> nil end) == %{a: nil}
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&map_values/2, [%URI{}, & &1]) end
    end

    test "raises FunctionClauseError for a function of the wrong arity" do
      assert_raise FunctionClauseError, fn -> apply(&map_values/2, [%{a: 1}, fn _k, v -> v end]) end
    end
  end

  describe "map_keys/2" do
    test "applies the function to each key and keeps the values" do
      assert map_keys(%{1 => :a, 2 => :b}, &(&1 * 10)) == %{10 => :a, 20 => :b}
    end

    test "keeps 1 and 1.0 as two new keys" do
      assert map_keys(%{a: 1, b: 2}, &if(&1 == :a, do: 1, else: 1.0)) == %{1 => 1, 1.0 => 2}
    end

    test "raises ArgumentError that tells each collision" do
      message = "more than one key has the same new key: :x for the keys [:a, :b]; :y for the keys [:c, :d]"

      assert_raise ArgumentError, message, fn ->
        map_keys(%{a: 1, b: 2, c: 3, d: 4}, &if(&1 in [:a, :b], do: :x, else: :y))
      end
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&map_keys/2, [%URI{}, & &1]) end
    end
  end

  describe "put_path/3" do
    test "makes each absent map on a path of three keys" do
      assert put_path(%{}, [:a, :b, :c], 1) == %{a: %{b: %{c: 1}}}
    end

    test "keeps the other entries of each map on the path" do
      assert put_path(%{a: %{x: 1, b: %{y: 2}}, z: 3}, [:a, :b, :c], 4) == %{a: %{x: 1, b: %{y: 2, c: 4}}, z: 3}
    end

    test "replaces the value at the last key" do
      assert put_path(%{a: %{b: 1}}, [:a, :b], 2) == %{a: %{b: 2}}
      assert put_path(%{a: %{b: %{c: 1}}}, [:a, :b], :flat) == %{a: %{b: :flat}}
    end

    test "accepts keys of any type" do
      assert put_path(%{}, ["a", 1, {:k}], :v) == %{"a" => %{1 => %{{:k} => :v}}}
    end

    test "raises ArgumentError for false or another value on the path that is not a map" do
      assert_raise ArgumentError, "the value at the path [:a, :b] is not a map: false", fn ->
        put_path(%{a: %{b: false}}, [:a, :b, :c], 1)
      end

      assert_raise ArgumentError, ~r/\[:a\] is not a map: \[1\]/, fn -> put_path(%{a: [1]}, [:a, :b], 1) end
    end

    test "accepts a field of a struct on the path, and raises KeyError for another key" do
      assert put_path(%{uri: %URI{}}, [:uri, :host], "example.com").uri.host == "example.com"
      assert_raise KeyError, fn -> put_path(%{uri: %URI{}}, [:uri, :nope], 1) end
      assert_raise KeyError, fn -> put_path(%URI{}, [:nope, :a], 1) end
      assert_raise KeyError, fn -> put_path(%{uri: %URI{}}, [:uri, :__struct__], Date) end
    end

    test "raises FunctionClauseError for an empty path and for a first argument that is not a map" do
      assert_raise FunctionClauseError, fn -> apply(&put_path/3, [%{}, [], 1]) end
      assert_raise FunctionClauseError, fn -> apply(&put_path/3, [[a: 1], [:a], 1]) end
    end
  end

  describe "fetch_keys/2" do
    test "returns only the given keys" do
      assert fetch_keys(%{a: 1, b: 2, c: 3}, [:a, :c]) == {:ok, %{a: 1, c: 3}}
    end

    test "returns an empty map for an empty list of keys" do
      assert fetch_keys(%{a: 1}, []) == {:ok, %{}}
    end

    test "lists each absent key one time, in the order of the keys" do
      assert fetch_keys(%{a: 1}, [:c, :a, :b, :c]) == {:error, {:missing_keys, [:c, :b]}}
    end

    test "treats a key with the value nil or false as present" do
      assert fetch_keys(%{a: nil, b: false}, [:a, :b]) == {:ok, %{a: nil, b: false}}
    end

    test "compares the keys with the strict equality operator" do
      assert fetch_keys(%{1 => :a}, [1.0]) == {:error, {:missing_keys, [1.0]}}
    end

    test "returns a plain map for a struct" do
      assert fetch_keys(%URI{host: "h"}, [:host]) == {:ok, %{host: "h"}}
    end

    test "raises FunctionClauseError for keys that are not a list" do
      assert_raise FunctionClauseError, fn -> apply(&fetch_keys/2, [%{a: 1}, :a]) end
    end
  end

  describe "compact/1" do
    test "removes only the entries with nil" do
      assert compact(%{a: nil, b: false, c: 0, d: ""}) == %{b: false, c: 0, d: ""}
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&compact/1, [%URI{}]) end
    end
  end

  describe "increment/3" do
    test "adds 1 by default, and puts the amount for an absent key" do
      assert increment(%{a: 1}, :a) == %{a: 2}
      assert increment(%{}, :a) == %{a: 1}
    end

    test "accepts a negative amount and a float" do
      assert increment(%{a: 1}, :a, -3) == %{a: -2}
      assert increment(%{a: 1}, :a, 0.5) == %{a: 1.5}
      assert increment(%{}, :a, 0.5) == %{a: 0.5}
    end

    test "raises ArithmeticError for a value that is not a number" do
      assert_raise ArithmeticError, fn -> increment(%{a: "1"}, :a) end
    end

    test "raises FunctionClauseError from increment/3 itself for a struct or an amount that is not a number" do
      for args <- [[%URI{}, :port, 1], [%{a: 1}, :a, "1"]] do
        error = assert_raise FunctionClauseError, fn -> apply(&increment/3, args) end
        assert {error.module, error.function} == {Shoddy.Maps, :increment}
      end
    end
  end

  describe "rename_key/3" do
    test "keeps the value and the other entries" do
      assert rename_key(%{a: 1, b: 2}, :a, :c) == %{c: 1, b: 2}
    end

    test "returns the map with no change for an absent key or the same key" do
      assert rename_key(%{a: 1}, :x, :y) == %{a: 1}
      assert rename_key(%{a: 1}, :a, :a) == %{a: 1}
    end

    test "keeps a value of nil" do
      assert rename_key(%{a: nil}, :a, :b) == %{b: nil}
    end

    test "treats 1 and 1.0 as two keys" do
      assert rename_key(%{1 => :x}, 1, 1.0) == %{1.0 => :x}
    end

    test "raises ArgumentError if the new key is already in the map" do
      assert_raise ArgumentError, "the new key :b is already in the map", fn -> rename_key(%{a: 1, b: 2}, :a, :b) end
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&rename_key/3, [%URI{}, :host, :name]) end
    end
  end

  describe "stringify_keys/1" do
    test "converts atoms, numbers and strings, and keeps a nested map" do
      assert stringify_keys(%{"s" => 1, 2 => 2, a: %{b: 1}}) == %{"s" => 1, "2" => 2, "a" => %{b: 1}}
    end

    test "raises ArgumentError if two keys give the same string" do
      assert_raise ArgumentError, ~r/same new key: "1"/, fn -> stringify_keys(%{1 => :a, "1" => :b}) end
    end

    test "converts a charlist key into a string" do
      assert stringify_keys(%{~c"a" => 1}) == %{"a" => 1}
    end

    test "raises ArgumentError for a list key that is not a charlist" do
      assert_raise ArgumentError, ~r/cannot convert the given list/, fn -> stringify_keys(%{[:a] => 1}) end
    end

    test "raises Protocol.UndefinedError for a tuple key" do
      assert_raise Protocol.UndefinedError, fn -> stringify_keys(%{{:a} => 1}) end
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&stringify_keys/1, [%URI{}]) end
    end
  end

  describe "diff/2" do
    test "compares the values with the strict equality operator" do
      assert diff(%{a: 1}, %{a: 1.0}) == %{added: %{}, removed: %{}, changed: %{a: {1, 1.0}}}
    end

    test "treats nil as a value" do
      assert diff(%{a: nil}, %{}) == %{added: %{}, removed: %{a: nil}, changed: %{}}
      assert diff(%{a: nil}, %{a: false}) == %{added: %{}, removed: %{}, changed: %{a: {nil, false}}}
    end

    test "returns a nested map that changed as one changed value" do
      assert diff(%{a: %{b: 1}}, %{a: %{b: 2}}) == %{added: %{}, removed: %{}, changed: %{a: {%{b: 1}, %{b: 2}}}}
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&diff/2, [%URI{}, %{}]) end
      assert_raise FunctionClauseError, fn -> apply(&diff/2, [%{}, %URI{}]) end
    end
  end

  describe "invert/1" do
    test "swaps keys and values of any type" do
      assert invert(%{"a" => nil, b: [1]}) == %{nil => "a", [1] => :b}
    end

    test "keeps 1 and 1.0 as two keys" do
      assert invert(%{a: 1, b: 1.0}) == %{1 => :a, 1.0 => :b}
    end

    test "raises ArgumentError that tells each value of more than one key" do
      assert_raise ArgumentError, "more than one key has the same value: [:x, :y]", fn ->
        invert(%{a: :x, b: :x, c: :y, d: :y, e: :z})
      end
    end

    test "raises FunctionClauseError for a struct" do
      assert_raise FunctionClauseError, fn -> apply(&invert/1, [%URI{}]) end
    end
  end
end
