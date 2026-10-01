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

    test "accepts a string that contains only whitespace, because it does not trim the string" do
      assert is_non_empty_string(" ")
      assert is_non_empty_string("\n\t")
    end

    test "accepts a binary that is not valid UTF-8, the encoding of a string" do
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

  describe "presence/1" do
    test "returns nil for the empty string and for nil" do
      assert presence("") == nil
      assert presence(nil) == nil
    end

    test "returns a string that is not empty with no change" do
      assert presence("Ada") == "Ada"
      assert presence(<<255>>) == <<255>>
    end

    test "returns a string that contains only whitespace with no change" do
      assert presence(" ") == " "
      assert presence("\n\t") == "\n\t"
    end

    test "returns false and each other value that is not a string with no change" do
      assert presence(false) == false
      assert presence(0) == 0
      assert presence([]) == []
      assert presence(~c"") == []
      assert presence(%{}) == %{}
    end
  end

  describe "truncate/3" do
    test "returns a string of max graphemes or fewer with no change" do
      assert truncate("abc", 3) == "abc"
      assert truncate("", 0, omission: "") == ""
      assert truncate("abc", 3, omission: "...") == "abc"
    end

    test "puts the omission at the end, and keeps the length at max" do
      assert truncate("abcdef", 4) == "abc…"
      assert truncate("abcdef", 5, omission: "..") == "abc.."
      assert String.length(truncate("abcdef", 4)) == 4
    end

    test "returns only the omission if it has max graphemes" do
      assert truncate("abcdef", 3, omission: "...") == "..."
    end

    test "returns an empty string for max 0 and an empty omission" do
      assert truncate("abc", 0, omission: "") == ""
    end

    test "never cuts a grapheme of more than one code point" do
      family = "\u{1F468}\u200D\u{1F469}\u200D\u{1F467}"
      accent = "e\u0301"

      assert truncate(family <> family <> family, 2) == family <> "…"
      assert truncate(accent <> accent <> accent, 2) == accent <> "…"
    end

    test "raises ArgumentError for an omission that is longer than max" do
      assert_raise ArgumentError, ~r/longer than the maximum length 2/, fn -> truncate("a", 2, omission: "...") end
      assert_raise ArgumentError, fn -> truncate("abc", 0) end
    end

    test "raises ArgumentError for an unknown option and for an omission that is not a string" do
      assert_raise ArgumentError, fn -> truncate("abc", 2, ellipsis: "") end
      assert_raise ArgumentError, ~r/expected a string/, fn -> truncate("abc", 2, omission: nil) end
    end

    test "raises FunctionClauseError from truncate/3 itself for an argument of the wrong type" do
      for args <- [["abc", -1, []], [nil, 3, []], ["abc", 2.0, []], ["abc", 2, :omission]] do
        error = assert_raise FunctionClauseError, fn -> apply(&truncate/3, args) end
        assert {error.module, error.function} == {Shoddy.Strings, :truncate}
      end
    end
  end

  describe "blank?/1" do
    test "returns true for nil, the empty string and whitespace" do
      assert blank?(nil)
      assert blank?("")
      assert blank?("  \t\r\n")
      assert blank?("\u00A0\u2003")
    end

    test "returns false for a string with another character" do
      refute blank?(" a ")
      refute blank?("0")
    end

    test "raises FunctionClauseError for a value that is not nil or a string" do
      for value <- [false, 0, [], :a] do
        error = assert_raise FunctionClauseError, fn -> apply(&blank?/1, [value]) end
        assert {error.module, error.function} == {Shoddy.Strings, :blank?}
      end
    end
  end

  describe "split_trim/2" do
    test "splits at the default separator, trims each value and removes each empty value" do
      assert split_trim(" a ,, b , ") == ["a", "b"]
      assert split_trim(" , ") == []
    end

    test "accepts another separator and a list of separators" do
      assert split_trim("a | b", "|") == ["a", "b"]
      assert split_trim("a;b,c", [";", ","]) == ["a", "b", "c"]
    end

    test "keeps the spaces inside a value" do
      assert split_trim("Ada Lovelace, Grace Hopper") == ["Ada Lovelace", "Grace Hopper"]
    end

    test "raises FunctionClauseError from split_trim/2 itself for an empty separator or a value that is not a string" do
      for args <- [["a", ""], [nil, ","], ["a", :comma]] do
        error = assert_raise FunctionClauseError, fn -> apply(&split_trim/2, args) end
        assert {error.module, error.function} == {Shoddy.Strings, :split_trim}
      end
    end
  end

  describe "truncate_bytes/2" do
    test "returns a string of max_bytes bytes or fewer with no change" do
      assert truncate_bytes("abc", 3) == "abc"
      assert truncate_bytes("", 0) == ""
    end

    test "returns an empty string for 0 bytes" do
      assert truncate_bytes("abc", 0) == ""
    end

    test "never cuts a grapheme of more than one code point" do
      family = "\u{1F468}\u200D\u{1F469}\u200D\u{1F467}"

      assert truncate_bytes(family <> "a", byte_size(family) - 1) == ""
      assert truncate_bytes(family <> "a", byte_size(family)) == family
      assert truncate_bytes("e\u0301x", 2) == ""
    end

    test "raises FunctionClauseError from truncate_bytes/2 itself for an argument of the wrong type" do
      for args <- [["abc", -1], [nil, 3], ["abc", 2.0]] do
        error = assert_raise FunctionClauseError, fn -> apply(&truncate_bytes/2, args) end
        assert {error.module, error.function} == {Shoddy.Strings, :truncate_bytes}
      end
    end
  end
end
