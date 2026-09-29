defmodule Shoddy.Hourglass do
  @moduledoc """
  Functions that change the precision of a time value.

  A `DateTime`, a `NaiveDateTime`, and a `Time` each keep the fractional part
  of the second in a `:microsecond` field. That field is a tuple. The first
  element is the value. The second element is the precision, which is a count
  of digits from 0 to 6.

  Elixir has `DateTime.truncate/2`, `NaiveDateTime.truncate/2`, and
  `Time.truncate/2`. Each of these functions lowers the precision.

  Elixir can also make the precision higher. A call to `DateTime.add/4` with
  an amount of 0 returns a value that has the precision of the unit.
  `NaiveDateTime.add/3` and `Time.add/3` do the same. These calls return the
  correct result, but the name `add` does not tell the reader the purpose of
  the call. `extend/2` returns the same result, and its name tells the
  purpose. It also accepts all three struct types.

  Two values that show the same point in time are not equal if the precision
  of each value is different. The operator `==` compares the two structs, and
  the precision is part of a struct.

      iex> ~U[2024-01-01 00:00:00Z] == ~U[2024-01-01 00:00:00.000000Z]
      false

      iex> DateTime.compare(~U[2024-01-01 00:00:00Z], ~U[2024-01-01 00:00:00.000000Z])
      :eq

  Give the two values the same precision before you compare them with `==`. A
  database column of the type `:utc_datetime_usec` also needs a precision of
  6.
  """

  @typedoc "A time value is a `DateTime`, a `NaiveDateTime`, or a `Time`."
  @type t :: DateTime.t() | NaiveDateTime.t() | Time.t()

  @typedoc "A precision is a name for a count of digits after the decimal point."
  @type precision :: :millisecond | :microsecond

  @precisions [:millisecond, :microsecond]

  defguardp is_time_value(value)
            when is_struct(value, DateTime) or is_struct(value, NaiveDateTime) or
                   is_struct(value, Time)

  @doc """
  Extends the precision of a time value.

  This function accepts a `DateTime`, a `NaiveDateTime`, or a `Time`. The
  default precision is `:microsecond`, which is 6 digits.

  This function never lowers the precision. If the value already has a higher
  precision than `precision`, this function returns the value with no change.
  To lower the precision, use `DateTime.truncate/2`,
  `NaiveDateTime.truncate/2`, or `Time.truncate/2`. Each of those functions
  accepts one struct type only.

  This function does not accept `:second`. A precision of 0 digits is the
  lowest precision, so a call with `:second` can never change a value. Such a
  call is always a mistake, and this function raises `FunctionClauseError`
  for it.

  This function changes the precision only. It does not change the value of
  the fractional second, so the point in time stays the same.

  Elixir does not force the digits after the precision to be zero. A value of
  `{123456, 3}` is correct, and it shows as `.123`. This function makes that
  value show as `.123456`. The two forms are the same point in time, and
  `DateTime.compare/2` returns `:eq` for them. `DateTime.add/4` also behaves in
  this way.

  ## Examples

  The function extends a value that has no fractional part:

      iex> Shoddy.Hourglass.extend(~U[2024-01-01 00:00:00Z])
      ~U[2024-01-01 00:00:00.000000Z]

      iex> Shoddy.Hourglass.extend(~N[2024-01-01 00:00:00])
      ~N[2024-01-01 00:00:00.000000]

      iex> Shoddy.Hourglass.extend(~T[12:00:00])
      ~T[12:00:00.000000]

  The function keeps the value of the fractional part:

      iex> Shoddy.Hourglass.extend(~U[2024-01-01 00:00:00.123Z])
      ~U[2024-01-01 00:00:00.123000Z]

  The function returns a value with no change if the precision is already 6:

      iex> Shoddy.Hourglass.extend(~U[2024-01-01 00:00:00.654321Z])
      ~U[2024-01-01 00:00:00.654321Z]

  The second argument selects the precision:

      iex> Shoddy.Hourglass.extend(~U[2024-01-01 00:00:00Z], :millisecond)
      ~U[2024-01-01 00:00:00.000Z]

  The function never lowers the precision:

      iex> Shoddy.Hourglass.extend(~U[2024-01-01 00:00:00.123456Z], :millisecond)
      ~U[2024-01-01 00:00:00.123456Z]

  Two values that are the same point in time and have the same precision are
  equal:

      iex> a = Shoddy.Hourglass.extend(~U[2024-01-01 00:00:00Z])
      iex> b = ~U[2024-01-01 00:00:00.000000Z]
      iex> a == b
      true
  """
  @spec extend(t(), precision()) :: t()
  def extend(time_value, precision \\ :microsecond)

  def extend(time_value, precision) when is_time_value(time_value) and precision in @precisions do
    {value, current} = time_value.microsecond
    %{time_value | microsecond: {value, max(current, digits(precision))}}
  end

  defp digits(:millisecond), do: 3
  defp digits(:microsecond), do: 6
end
