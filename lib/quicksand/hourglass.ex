defmodule Quicksand.Hourglass do
  @moduledoc """
  Functions that change the precision of a time value.

  A `DateTime`, a `NaiveDateTime`, and a `Time` each keep the fractional part
  of the second in a `:microsecond` field. That field is a tuple. The first
  element is the value. The second element is the precision, which is a count
  of digits from 0 to 6.

  Elixir has `DateTime.truncate/2`, which lowers the precision. Elixir has no
  function that makes the precision higher. `extend/2` does that.

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

  @typedoc "A time value that has a `:microsecond` field."
  @type t :: DateTime.t() | NaiveDateTime.t() | Time.t()

  @typedoc "A name for a count of digits after the decimal point."
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
  To lower the precision, use `DateTime.truncate/2`.

  This function does not accept `:second`. A precision of 0 digits is the
  lowest precision, so such a call can never change a value. A call that gives
  `:second` is thus a mistake, and this function raises `FunctionClauseError`
  for it.

  A change of the precision does not change the point in time, because this
  function adds digits that are zero.

  ## Examples

  The function extends a value that has no fractional part:

      iex> Quicksand.Hourglass.extend(~U[2024-01-01 00:00:00Z])
      ~U[2024-01-01 00:00:00.000000Z]

      iex> Quicksand.Hourglass.extend(~N[2024-01-01 00:00:00])
      ~N[2024-01-01 00:00:00.000000]

      iex> Quicksand.Hourglass.extend(~T[12:00:00])
      ~T[12:00:00.000000]

  The function keeps the value of the fractional part:

      iex> Quicksand.Hourglass.extend(~U[2024-01-01 00:00:00.123Z])
      ~U[2024-01-01 00:00:00.123000Z]

  The function returns a value with no change if the precision is already 6:

      iex> Quicksand.Hourglass.extend(~U[2024-01-01 00:00:00.654321Z])
      ~U[2024-01-01 00:00:00.654321Z]

  The second argument selects the precision:

      iex> Quicksand.Hourglass.extend(~U[2024-01-01 00:00:00Z], :millisecond)
      ~U[2024-01-01 00:00:00.000Z]

  The function never lowers the precision:

      iex> Quicksand.Hourglass.extend(~U[2024-01-01 00:00:00.123456Z], :millisecond)
      ~U[2024-01-01 00:00:00.123456Z]

  Two values with the same precision are equal:

      iex> a = Quicksand.Hourglass.extend(~U[2024-01-01 00:00:00Z])
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
