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

  describe "blank?/1" do
    property "returns true only for nil or a string that String.trim/1 makes empty" do
      check all(
              value <-
                one_of([constant(nil), string(:printable, max_length: 5), member_of([" ", "\t", "\n", "\u00A0"])])
            ) do
        assert Shoddy.Strings.blank?(value) == (is_nil(value) or String.trim(value) == "")
      end
    end
  end

  describe "split_trim/2" do
    property "returns the values of Enum.join/2 again, if each value is trimmed and not empty" do
      check all(
              values <- list_of(string(:alphanumeric, min_length: 1), max_length: 5),
              padding <- member_of(["", " ", "  "])
            ) do
        text = Enum.map_join(values, ",", &(padding <> &1 <> padding))

        assert Shoddy.Strings.split_trim(text) == values
      end
    end
  end

  describe "truncate_bytes/2" do
    property "returns the longest start of full graphemes that has max_bytes bytes or fewer" do
      check all(string <- string(:printable, max_length: 10), max_bytes <- integer(0..40)) do
        result = Shoddy.Strings.truncate_bytes(string, max_bytes)
        graphemes = String.graphemes(string)
        count = length(String.graphemes(result))

        assert byte_size(result) <= max_bytes
        assert result == Enum.join(Enum.take(graphemes, count))
        assert count == length(graphemes) or byte_size(Enum.join(Enum.take(graphemes, count + 1))) > max_bytes
      end
    end
  end

  describe "mask/2" do
    property "keeps the length, and shows at most the given graphemes of a longer string" do
      check all(string <- string(:printable, max_length: 12), first <- integer(0..4), last <- integer(0..4)) do
        result = Shoddy.Strings.mask(string, keep_first: first, keep_last: last, char: "*")
        graphemes = String.graphemes(string)
        count = length(graphemes)

        assert String.length(result) == count

        if first + last >= count do
          assert result == String.duplicate("*", count)
        else
          assert String.starts_with?(result, Enum.join(Enum.take(graphemes, first)))
          assert String.ends_with?(result, Enum.join(Enum.take(graphemes, -last)))
        end
      end
    end
  end

  describe "ensure_prefix/2" do
    property "returns a string that starts with the prefix, and adds it only if it is absent" do
      check all(string <- string(:alphanumeric, max_length: 5), prefix <- string(:alphanumeric, max_length: 3)) do
        result = Shoddy.Strings.ensure_prefix(string, prefix)

        assert String.starts_with?(result, prefix)
        assert result == if(String.starts_with?(string, prefix), do: string, else: prefix <> string)
      end
    end
  end

  describe "ensure_suffix/2" do
    property "returns a string that ends with the suffix, and adds it only if it is absent" do
      check all(string <- string(:alphanumeric, max_length: 5), suffix <- string(:alphanumeric, max_length: 3)) do
        result = Shoddy.Strings.ensure_suffix(string, suffix)

        assert String.ends_with?(result, suffix)
        assert result == if(String.ends_with?(string, suffix), do: string, else: string <> suffix)
      end
    end
  end
end
