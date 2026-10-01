defmodule Shoddy.NumbersPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Numbers

  describe "ceil_div/2" do
    property "returns the ceiling of the quotient" do
      check all(dividend <- integer(), divisor <- filter(integer(), &(&1 != 0))) do
        q = Numbers.ceil_div(dividend, divisor)

        # The ceiling q obeys q - 1 < dividend / divisor <= q. A multiplication
        # by a negative divisor changes the direction of each comparison.
        if divisor > 0 do
          assert q * divisor >= dividend and (q - 1) * divisor < dividend
        else
          assert q * divisor <= dividend and (q - 1) * divisor > dividend
        end
      end
    end
  end

  describe "clamp/3" do
    property "returns the value if it is in the range, and the nearest limit otherwise" do
      check all(value <- integer(), low <- integer(), span <- integer(0..100)) do
        high = low + span

        assert Numbers.clamp(value, low, high) == value |> max(low) |> min(high)
      end
    end
  end

  describe "mean/1" do
    property "returns the sum divided by the count, or :empty" do
      check all(list <- list_of(integer(-100..100), max_length: 10)) do
        expected = if list == [], do: {:error, :empty}, else: {:ok, Enum.sum(list) / length(list)}

        assert Numbers.mean(list) == expected
      end
    end
  end
end
