defmodule Shoddy.DateTimesTest do
  use ExUnit.Case, async: true

  import Shoddy.DateTimes

  doctest Shoddy.DateTimes

  describe "extend_precision/1" do
    test "extends a DateTime that has no fractional part" do
      assert extend_precision(~U[2024-01-01 00:00:00Z]) == ~U[2024-01-01 00:00:00.000000Z]
    end

    test "extends a NaiveDateTime that has no fractional part" do
      assert extend_precision(~N[2024-01-01 00:00:00]) == ~N[2024-01-01 00:00:00.000000]
    end

    test "extends a Time that has no fractional part" do
      assert extend_precision(~T[12:00:00]) == ~T[12:00:00.000000]
    end

    test "keeps the value of the fractional part" do
      assert extend_precision(~U[2024-01-01 00:00:00.123Z]) == ~U[2024-01-01 00:00:00.123000Z]
    end

    test "returns a value with a precision of 6 with no change" do
      value = ~U[2024-01-01 00:00:00.654321Z]
      assert extend_precision(value) == value
    end

    test "does not change the point in time" do
      value = ~U[2024-01-01 00:00:00Z]
      assert DateTime.compare(extend_precision(value), value) == :eq
    end

    test "makes two equal points in time equal for the operator ==" do
      assert extend_precision(~U[2024-01-01 00:00:00Z]) == ~U[2024-01-01 00:00:00.000000Z]
      refute ~U[2024-01-01 00:00:00Z] == ~U[2024-01-01 00:00:00.000000Z]
    end

    test "keeps the time zone of a DateTime" do
      value = ~U[2024-01-01 00:00:00Z]
      extended = extend_precision(value)
      assert extended.time_zone == value.time_zone
      assert extended.utc_offset == value.utc_offset
    end
  end

  describe "the digits after the precision" do
    test "shows those digits, and agrees with Time.add/3" do
      # Elixir does not force these digits to be zero, so this value is correct.
      value = Time.new!(0, 0, 0, {123_456, 3})
      assert Time.to_iso8601(value) == "00:00:00.123"
      assert Time.to_iso8601(extend_precision(value)) == "00:00:00.123456"
      assert extend_precision(value) == Time.add(value, 0, :microsecond)
    end

    test "does not change the point in time" do
      value = DateTime.new!(~D[2024-01-01], Time.new!(0, 0, 0, {123_456, 3}))
      assert DateTime.compare(extend_precision(value), value) == :eq
    end
  end

  describe "extend_precision/2" do
    test "extends to a precision of 3 for :millisecond" do
      assert extend_precision(~U[2024-01-01 00:00:00Z], :millisecond).microsecond == {0, 3}
    end

    test "extends to a precision of 6 for :microsecond" do
      assert extend_precision(~U[2024-01-01 00:00:00Z], :microsecond).microsecond == {0, 6}
    end

    test "never lowers the precision" do
      value = ~U[2024-01-01 00:00:00.123456Z]
      assert extend_precision(value, :millisecond) == value
    end

    test "raises FunctionClauseError for :second, which can never change a value" do
      assert_raise FunctionClauseError, fn -> extend_precision(~U[2024-01-01 00:00:00Z], :second) end
    end

    test "raises FunctionClauseError for a precision that is not known" do
      assert_raise FunctionClauseError, fn -> extend_precision(~U[2024-01-01 00:00:00Z], :nanosecond) end
    end

    test "raises FunctionClauseError for a Date, which has no fractional part" do
      assert_raise FunctionClauseError, fn -> extend_precision(~D[2024-01-01], :microsecond) end
    end

    test "raises FunctionClauseError for a value that is not a time value" do
      assert_raise FunctionClauseError, fn -> extend_precision(42, :microsecond) end
    end
  end

  describe "floor/2" do
    test "rounds a DateTime down to the start of a minute, an hour and a day" do
      value = ~U[2024-03-15 12:34:56.789012Z]

      assert floor(value, :minute) == ~U[2024-03-15 12:34:00.000000Z]
      assert floor(value, :hour) == ~U[2024-03-15 12:00:00.000000Z]
      assert floor(value, :day) == ~U[2024-03-15 00:00:00.000000Z]
    end

    test "rounds a NaiveDateTime down to the start of a minute, an hour and a day" do
      value = ~N[2024-03-15 12:34:56.789]

      assert floor(value, :minute) == ~N[2024-03-15 12:34:00.000]
      assert floor(value, :hour) == ~N[2024-03-15 12:00:00.000]
      assert floor(value, :day) == ~N[2024-03-15 00:00:00.000]
    end

    test "rounds a Time down to the start of a minute and an hour" do
      assert floor(~T[12:34:56], :minute) == ~T[12:34:00]
      assert floor(~T[12:34:56], :hour) == ~T[12:00:00]
    end

    test "keeps the precision of the fractional second" do
      assert floor(~U[2024-03-15 12:34:56.7Z], :hour).microsecond == {0, 1}
      assert floor(~U[2024-03-15 12:34:56Z], :hour).microsecond == {0, 0}
    end

    test "returns a value at the start of the unit with no change" do
      value = ~U[2024-03-15 00:00:00Z]
      assert floor(value, :day) == value
    end

    test "raises FunctionClauseError for a DateTime in a time zone other than UTC" do
      value = %{
        ~U[2024-03-15 12:34:56Z]
        | time_zone: "Europe/Paris",
          zone_abbr: "CET",
          utc_offset: 3600
      }

      assert_raise FunctionClauseError, fn -> floor(value, :hour) end
    end

    test "raises FunctionClauseError for a Time and the unit :day" do
      assert_raise FunctionClauseError, fn -> apply(&floor/2, [~T[12:34:56], :day]) end
    end

    test "raises FunctionClauseError for a unit that is not known" do
      assert_raise FunctionClauseError, fn -> apply(&floor/2, [~U[2024-03-15 12:34:56Z], :second]) end
    end

    test "raises FunctionClauseError for a Date" do
      assert_raise FunctionClauseError, fn -> apply(&floor/2, [~D[2024-03-15], :day]) end
    end
  end

  describe "ceil/2" do
    test "rounds a DateTime up to the start of the next minute, hour and day" do
      value = ~U[2024-03-15 12:34:56.789012Z]

      assert ceil(value, :minute) == ~U[2024-03-15 12:35:00.000000Z]
      assert ceil(value, :hour) == ~U[2024-03-15 13:00:00.000000Z]
      assert ceil(value, :day) == ~U[2024-03-16 00:00:00.000000Z]
    end

    test "rounds a NaiveDateTime up to the start of the next minute, hour and day" do
      value = ~N[2024-03-15 12:34:56.789]

      assert ceil(value, :minute) == ~N[2024-03-15 12:35:00.000]
      assert ceil(value, :hour) == ~N[2024-03-15 13:00:00.000]
      assert ceil(value, :day) == ~N[2024-03-16 00:00:00.000]
    end

    test "goes into the next month and the next year" do
      assert ceil(~U[2024-02-29 23:59:59Z], :day) == ~U[2024-03-01 00:00:00Z]
      assert ceil(~N[2024-12-31 23:59:00.1], :minute) == ~N[2025-01-01 00:00:00.0]
    end

    test "keeps the precision of the fractional second" do
      assert ceil(~U[2024-03-15 12:34:56.7Z], :hour).microsecond == {0, 1}
      assert ceil(~U[2024-03-15 12:34:56Z], :hour).microsecond == {0, 0}
    end

    test "returns a value at the start of the unit with no change" do
      assert ceil(~U[2024-03-15 00:00:00Z], :day) == ~U[2024-03-15 00:00:00Z]
      assert ceil(~U[2024-03-15 13:00:00.000Z], :hour) == ~U[2024-03-15 13:00:00.000Z]
      assert ceil(~N[2024-03-15 12:34:00], :minute) == ~N[2024-03-15 12:34:00]
    end

    test "rounds up a value that is one microsecond after the start of the unit" do
      assert ceil(~U[2024-03-15 00:00:00.000001Z], :day) == ~U[2024-03-16 00:00:00.000000Z]
    end

    test "rounds up a value with a fractional second above zero and a precision of 0" do
      value = %{~U[2024-03-15 12:00:00Z] | microsecond: {500_000, 0}}

      assert ceil(value, :hour) == ~U[2024-03-15 13:00:00Z]
    end

    test "raises FunctionClauseError for a DateTime in a time zone other than UTC" do
      value = %{
        ~U[2024-03-15 12:34:56Z]
        | time_zone: "Europe/Paris",
          zone_abbr: "CET",
          utc_offset: 3600
      }

      assert_raise FunctionClauseError, fn -> ceil(value, :hour) end
    end

    test "raises FunctionClauseError for a Time" do
      assert_raise FunctionClauseError, fn -> apply(&ceil/2, [~T[12:34:56], :hour]) end
      assert_raise FunctionClauseError, fn -> apply(&ceil/2, [~T[23:30:00], :hour]) end
    end

    test "raises FunctionClauseError for a unit that is not known" do
      assert_raise FunctionClauseError, fn -> apply(&ceil/2, [~U[2024-03-15 12:34:56Z], :second]) end
    end

    test "raises FunctionClauseError for a Date" do
      assert_raise FunctionClauseError, fn -> apply(&ceil/2, [~D[2024-03-15], :day]) end
    end
  end
end
