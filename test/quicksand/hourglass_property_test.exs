defmodule Quicksand.HourglassPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Quicksand.Hourglass

  @digits %{millisecond: 3, microsecond: 6}

  defp precision_name, do: member_of([:millisecond, :microsecond])

  # Elixir keeps the fractional second as a tuple of a value and a precision.
  # Elixir does not force the digits after the precision to be zero. The guard
  # of Calendar.ISO checks the range of each element only. Thus a value such as
  # {123456, 3} is correct, and Elixir itself constructs one. This generator
  # therefore makes values with digits after the precision, because extend/2
  # must be correct for them.
  #
  # A first form of this generator removed those digits. That form rested on a
  # belief about Elixir that is not true, and it hid a whole class of input
  # from every property in this file.
  defp fraction do
    gen all(value <- integer(0..999_999), precision <- integer(0..6)) do
      {value, precision}
    end
  end

  defp datetime do
    gen all(seconds <- integer(0..4_102_444_800), microsecond <- fraction()) do
      %{DateTime.from_unix!(seconds) | microsecond: microsecond}
    end
  end

  defp naive_datetime do
    gen all(value <- datetime()) do
      DateTime.to_naive(value)
    end
  end

  defp time do
    gen all(value <- datetime()) do
      DateTime.to_time(value)
    end
  end

  defp time_value, do: one_of([datetime(), naive_datetime(), time()])

  describe "extend/2" do
    property "never lowers the precision" do
      check all(value <- time_value(), name <- precision_name()) do
        {_, before} = value.microsecond
        {_, result} = Hourglass.extend(value, name).microsecond
        assert result >= before
      end
    end

    property "gives the higher of the current precision and the argument" do
      check all(value <- time_value(), name <- precision_name()) do
        {_, before} = value.microsecond
        {_, result} = Hourglass.extend(value, name).microsecond
        assert result == max(before, @digits[name])
      end
    end

    property "never changes the value of the fractional second" do
      check all(value <- time_value(), name <- precision_name()) do
        {before, _} = value.microsecond
        {result, _} = Hourglass.extend(value, name).microsecond
        assert result == before
      end
    end

    property "is idempotent" do
      check all(value <- time_value(), name <- precision_name()) do
        once = Hourglass.extend(value, name)
        assert Hourglass.extend(once, name) == once
      end
    end

    property "changes no field other than the precision" do
      check all(value <- time_value(), name <- precision_name()) do
        result = Hourglass.extend(value, name)
        assert %{result | microsecond: value.microsecond} == value
      end
    end

    property "keeps the struct type" do
      check all(value <- time_value(), name <- precision_name()) do
        assert Hourglass.extend(value, name).__struct__ == value.__struct__
      end
    end
  end

  describe "extend/1" do
    property "always gives a precision of 6" do
      check all(value <- time_value()) do
        assert {_, 6} = Hourglass.extend(value).microsecond
      end
    end

    property "gives the same result as DateTime.add/4 with an amount of 0" do
      # The moduledoc states this agreement. If the two ever differ, the
      # moduledoc is wrong and this property says so.
      check all(value <- datetime()) do
        assert Hourglass.extend(value) == DateTime.add(value, 0, :microsecond)
      end
    end

    property "does not change the point in time" do
      check all(value <- datetime()) do
        assert DateTime.compare(Hourglass.extend(value), value) == :eq
      end
    end

    property "makes two equal points in time equal for the operator ==" do
      check all(value <- datetime()) do
        other = %{value | microsecond: {elem(value.microsecond, 0), 6}}
        assert Hourglass.extend(value) == Hourglass.extend(other)
      end
    end

    property "gives a result that DateTime.truncate/2 returns to the second" do
      check all(value <- datetime()) do
        assert value |> Hourglass.extend() |> DateTime.truncate(:second) ==
                 DateTime.truncate(value, :second)
      end
    end
  end
end
