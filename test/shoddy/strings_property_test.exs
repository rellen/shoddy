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
end
