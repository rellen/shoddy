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

  describe "get_present/3" do
    property "returns the default for an absent key or nil, and the value of Keyword.get/2 otherwise" do
      check all(keywords <- list_of(tuple({key(), one_of([constant(nil), simple()])}), max_length: 6), key <- key()) do
        expected = if is_nil(Keyword.get(keywords, key)), do: :default, else: Keyword.get(keywords, key)

        assert Keywords.get_present(keywords, key, :default) === expected
      end
    end
  end

  describe "compact/1" do
    property "returns the entries that are not nil, in the same order" do
      check all(keywords <- list_of(tuple({key(), one_of([constant(nil), simple()])}), max_length: 6)) do
        assert Keywords.compact(keywords) == Enum.reject(keywords, &is_nil(elem(&1, 1)))
      end
    end
  end
end
