defmodule Shoddy.ParsePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Parse

  describe "integer/2" do
    property "returns the integer for its own text, and checks the limits" do
      check all(
              value <- integer(),
              min <- one_of([constant(nil), integer()]),
              span <- integer(0..1_000)
            ) do
        max = if min, do: min + span

        expected =
          cond do
            min && value < min -> {:error, :too_small}
            max && value > max -> {:error, :too_large}
            true -> {:ok, value}
          end

        assert Parse.integer(Integer.to_string(value), min: min, max: max) == expected
      end
    end
  end

  describe "one_of/2" do
    property "returns the allowed atom with the same name, and :not_allowed for other text" do
      check all(
              allowed <- list_of(atom(:alphanumeric), max_length: 5),
              text <- one_of([string(:alphanumeric), member_of(Enum.map([:x | allowed], &Atom.to_string/1))])
            ) do
        expected =
          case Enum.find(allowed, &(Atom.to_string(&1) == text)) do
            nil -> {:error, :not_allowed}
            atom -> {:ok, atom}
          end

        assert Parse.one_of(text, allowed) == expected
      end
    end
  end
end
