defmodule Shoddy.StringsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  require Shoddy.Strings

  describe "is_non_empty_string/1" do
    property "matches a binary of at least one byte, and nothing else" do
      check all(
              value <-
                one_of([
                  string(:printable),
                  binary(),
                  bitstring(),
                  constant(nil),
                  boolean(),
                  integer(),
                  atom(:alphanumeric),
                  list_of(integer(0..127), max_length: 3)
                ])
            ) do
        guard = fn
          x when Shoddy.Strings.is_non_empty_string(x) -> true
          _x -> false
        end

        assert guard.(value) == match?(<<_, _::binary>>, value)
      end
    end
  end

  describe "presence/1" do
    property "returns nil for the empty string, and each other value with no change" do
      check all(
              value <-
                one_of([
                  string(:printable),
                  binary(),
                  constant(nil),
                  boolean(),
                  integer(),
                  list_of(integer(0..127), max_length: 3)
                ])
            ) do
        expected = if value != "", do: value

        assert Shoddy.Strings.presence(value) === expected
      end
    end
  end

  describe "truncate/3" do
    property "returns a string of max graphemes or fewer that starts as the input, and ends in the omission if it is shorter" do
      check all(
              string <- string(:printable, max_length: 20),
              omission <- member_of(["", "…", "..."]),
              max <- integer(String.length(omission)..25)
            ) do
        result = Shoddy.Strings.truncate(string, max, omission: omission)

        if String.length(string) <= max do
          assert result == string
        else
          assert String.length(result) == max
          assert String.ends_with?(result, omission)
          assert String.starts_with?(string, String.slice(result, 0, max - String.length(omission)))
        end
      end
    end
  end
end
