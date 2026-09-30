defmodule Shoddy.KeywordsPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Keywords

  defp simple, do: one_of([integer(), atom(:alphanumeric), string(:alphanumeric), boolean()])

  defp key, do: member_of([:a, :b, :c])

  defp keywords, do: list_of(tuple({key(), simple()}), max_length: 6)

  describe "put_if/3" do
    property "returns the list with no change for a falsy value, and the result of Keyword.put/3 for other values" do
      check all(keywords <- keywords(), key <- key(), value <- one_of([constant(nil), simple()])) do
        expected = if value, do: Keyword.put(keywords, key, value), else: keywords
        assert Keywords.put_if(keywords, key, value) == expected
      end
    end
  end

  describe "put_present/3" do
    property "returns the list with no change for nil, and the result of Keyword.put/3 for other values" do
      check all(keywords <- keywords(), key <- key(), value <- one_of([constant(nil), simple()])) do
        expected = if is_nil(value), do: keywords, else: Keyword.put(keywords, key, value)
        assert Keywords.put_present(keywords, key, value) == expected
      end
    end
  end
end
