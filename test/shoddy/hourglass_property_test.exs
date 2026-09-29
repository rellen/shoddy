defmodule Shoddy.HourglassPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Shoddy.Hourglass

  @digits %{millisecond: 3, microsecond: 6}

  defp precision_name, do: member_of([:millisecond, :microsecond])

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

    property "sets the precision to the higher of the current precision and the argument" do
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

    property "makes no further change on a second call" do
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
    property "always sets the precision to 6" do
      check all(value <- time_value()) do
        assert {_, 6} = Hourglass.extend(value).microsecond
      end
    end

    property "returns the same result as DateTime.add/4 with an amount of 0" do
      # The moduledoc states that the two results are the same. If they
      # differ, the moduledoc is wrong, and this property fails.
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

    property "returns a value that truncates to the same second as the argument" do
      check all(value <- datetime()) do
        assert value |> Hourglass.extend() |> DateTime.truncate(:second) ==
                 DateTime.truncate(value, :second)
      end
    end
  end
end
