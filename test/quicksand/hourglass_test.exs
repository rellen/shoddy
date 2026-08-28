defmodule Quicksand.HourglassTest do
  use ExUnit.Case, async: true

  import Quicksand.Hourglass

  doctest Quicksand.Hourglass

  describe "extend/1" do
    test "extends a DateTime that has no fractional part" do
      assert extend(~U[2024-01-01 00:00:00Z]) == ~U[2024-01-01 00:00:00.000000Z]
    end

    test "extends a NaiveDateTime that has no fractional part" do
      assert extend(~N[2024-01-01 00:00:00]) == ~N[2024-01-01 00:00:00.000000]
    end

    test "extends a Time that has no fractional part" do
      assert extend(~T[12:00:00]) == ~T[12:00:00.000000]
    end

    test "keeps the value of the fractional part" do
      assert extend(~U[2024-01-01 00:00:00.123Z]) == ~U[2024-01-01 00:00:00.123000Z]
    end

    test "returns a value with a precision of 6 with no change" do
      value = ~U[2024-01-01 00:00:00.654321Z]
      assert extend(value) == value
    end

    test "does not change the point in time" do
      value = ~U[2024-01-01 00:00:00Z]
      assert DateTime.compare(extend(value), value) == :eq
    end

    test "makes two equal points in time equal for the operator ==" do
      assert extend(~U[2024-01-01 00:00:00Z]) == ~U[2024-01-01 00:00:00.000000Z]
      refute ~U[2024-01-01 00:00:00Z] == ~U[2024-01-01 00:00:00.000000Z]
    end

    test "keeps the time zone of a DateTime" do
      value = ~U[2024-01-01 00:00:00Z]
      extended = extend(value)
      assert extended.time_zone == value.time_zone
      assert extended.utc_offset == value.utc_offset
    end
  end

  describe "the digits after the precision" do
    test "reveals them, and agrees with the add function of the standard library" do
      # Elixir does not force these digits to be zero, so this value is correct.
      value = Time.new!(0, 0, 0, {123_456, 3})
      assert Time.to_iso8601(value) == "00:00:00.123"
      assert Time.to_iso8601(extend(value)) == "00:00:00.123456"
      assert extend(value) == Time.add(value, 0, :microsecond)
    end

    test "does not change the point in time" do
      value = DateTime.new!(~D[2024-01-01], Time.new!(0, 0, 0, {123_456, 3}))
      assert DateTime.compare(extend(value), value) == :eq
    end
  end

  describe "extend/2" do
    test "extends to a precision of 3 for :millisecond" do
      assert extend(~U[2024-01-01 00:00:00Z], :millisecond).microsecond == {0, 3}
    end

    test "extends to a precision of 6 for :microsecond" do
      assert extend(~U[2024-01-01 00:00:00Z], :microsecond).microsecond == {0, 6}
    end

    test "never lowers the precision" do
      value = ~U[2024-01-01 00:00:00.123456Z]
      assert extend(value, :millisecond) == value
    end

    test "raises FunctionClauseError for :second, which can never change a value" do
      assert_raise FunctionClauseError, fn -> extend(~U[2024-01-01 00:00:00Z], :second) end
    end

    test "raises FunctionClauseError for a precision that is not known" do
      assert_raise FunctionClauseError, fn -> extend(~U[2024-01-01 00:00:00Z], :nanosecond) end
    end

    test "raises FunctionClauseError for a Date, which has no fractional part" do
      assert_raise FunctionClauseError, fn -> extend(~D[2024-01-01], :microsecond) end
    end

    test "raises FunctionClauseError for a value that is not a time value" do
      assert_raise FunctionClauseError, fn -> extend(42, :microsecond) end
    end
  end
end
