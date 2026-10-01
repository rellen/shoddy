defmodule Shoddy.StringsTest do
  use ExUnit.Case, async: true

  import Shoddy.Strings

  doctest Shoddy.Strings

  describe "is_non_empty_string/1" do
    test "accepts a string that contains at least one byte" do
      assert is_non_empty_string("a")
      assert is_non_empty_string("Ada Lovelace")
      assert is_non_empty_string("ü")
    end

    test "rejects nil and the empty string" do
      refute is_non_empty_string(nil)
      refute is_non_empty_string("")
    end

    test "accepts a string of whitespace, because it does not trim the string" do
      assert is_non_empty_string(" ")
      assert is_non_empty_string("\n\t")
    end

    test "accepts a binary that is not valid UTF-8" do
      assert is_non_empty_string(<<255>>)
    end

    test "rejects a value that is not a binary" do
      refute is_non_empty_string(false)
      refute is_non_empty_string(:ada)
      refute is_non_empty_string(~c"Ada")
      refute is_non_empty_string(0)
      refute is_non_empty_string(["Ada"])
    end

    test "rejects a bitstring that is not a binary" do
      refute is_non_empty_string(<<1::3>>)
    end

    test "operates in a guard clause" do
      classify = fn
        x when is_non_empty_string(x) -> :string
        _x -> :blank
      end

      assert classify.("Ada") == :string
      assert classify.("") == :blank
      assert classify.(nil) == :blank
    end

    test "operates as a capture for Enum.filter/2" do
      assert Enum.filter(["Ada", "", nil, " "], &is_non_empty_string/1) == ["Ada", " "]
    end
  end
end
