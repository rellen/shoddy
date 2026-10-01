defmodule Shoddy.DateTimes do
  @moduledoc """
  Functions that operate on dates and times, and add to the standard modules
  `Date`, `DateTime`, `NaiveDateTime` and `Time`.

  The name of this module is `DateTimes`, in the plural. Thus the alias
  `DateTimes` does not hide the standard `DateTime` module.

  The module contains these functions:

  - `extend_precision/2` makes the precision of the fractional second
    higher.
  - `floor/2` rounds a value down to the start of a minute, an hour or a
    day.
  - `ceil/2` rounds a value up to the start of a minute, an hour or a day.
  - `next_start/2` returns the start of the next minute, hour or day. The
    result is always after the value.
  - `between?/3` tells if a value is in a period. It also accepts a `Date`.
  - `overlap?/2` tells if two periods have a value in common.

  ## Precision

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
  the call. `extend_precision/2` returns the same result, and its name
  tells the purpose. It also accepts all three struct types.

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

  @typedoc "A unit is the length of time that `floor/2` and `ceil/2` round a value to."
  @type unit :: :minute | :hour | :day

  @precisions [:millisecond, :microsecond]
  @units [:minute, :hour, :day]

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

      iex> Shoddy.DateTimes.extend_precision(~U[2024-01-01 00:00:00Z])
      ~U[2024-01-01 00:00:00.000000Z]

      iex> Shoddy.DateTimes.extend_precision(~N[2024-01-01 00:00:00])
      ~N[2024-01-01 00:00:00.000000]

      iex> Shoddy.DateTimes.extend_precision(~T[12:00:00])
      ~T[12:00:00.000000]

  The function keeps the value of the fractional part:

      iex> Shoddy.DateTimes.extend_precision(~U[2024-01-01 00:00:00.123Z])
      ~U[2024-01-01 00:00:00.123000Z]

  The function returns a value with no change if the precision is already 6:

      iex> Shoddy.DateTimes.extend_precision(~U[2024-01-01 00:00:00.654321Z])
      ~U[2024-01-01 00:00:00.654321Z]

  The second argument selects the precision:

      iex> Shoddy.DateTimes.extend_precision(~U[2024-01-01 00:00:00Z], :millisecond)
      ~U[2024-01-01 00:00:00.000Z]

  The function never lowers the precision:

      iex> Shoddy.DateTimes.extend_precision(~U[2024-01-01 00:00:00.123456Z], :millisecond)
      ~U[2024-01-01 00:00:00.123456Z]

  Two values that are the same point in time and have the same precision are
  equal:

      iex> a = Shoddy.DateTimes.extend_precision(~U[2024-01-01 00:00:00Z])
      iex> b = ~U[2024-01-01 00:00:00.000000Z]
      iex> a == b
      true
  """
  @spec extend_precision(t(), precision()) :: t()
  def extend_precision(time_value, precision \\ :microsecond)

  def extend_precision(time_value, precision) when is_time_value(time_value) and precision in @precisions do
    {value, current} = time_value.microsecond
    %{time_value | microsecond: {value, max(current, digits(precision))}}
  end

  defp digits(:millisecond), do: 3
  defp digits(:microsecond), do: 6

  @doc """
  Rounds a time value down to the start of a unit.

  The unit is `:minute`, `:hour` or `:day`. This function sets each field
  below the unit to zero. For example, `:hour` sets the minute, the second
  and the fractional second to zero. The precision of the fractional second
  stays the same.

  This function accepts a `NaiveDateTime`, a `Time`, and a `DateTime` in the
  time zone `Etc/UTC`. A `Time` has no day, so it accepts only `:minute` and
  `:hour`.

  This function raises `FunctionClauseError` for a `DateTime` in another
  time zone. In some time zones, the start of a unit does not exist on the
  day of a change to daylight saving time. The correct result then needs a
  time zone database, and this function does not use one. Convert the value
  to UTC with `DateTime.shift_zone/2` first, or use a `NaiveDateTime`.

  Use this function to put events into groups by the minute, the hour or the
  day, or to find the start of the current day.

  ## Examples

      iex> Shoddy.DateTimes.floor(~U[2024-01-01 12:34:56.789Z], :hour)
      ~U[2024-01-01 12:00:00.000Z]

      iex> Shoddy.DateTimes.floor(~U[2024-01-01 12:34:56Z], :minute)
      ~U[2024-01-01 12:34:00Z]

      iex> Shoddy.DateTimes.floor(~N[2024-01-01 12:34:56], :day)
      ~N[2024-01-01 00:00:00]

      iex> Shoddy.DateTimes.floor(~T[12:34:56.789012], :hour)
      ~T[12:00:00.000000]

  A value at the start of the unit stays the same:

      iex> Shoddy.DateTimes.floor(~U[2024-01-01 12:00:00Z], :hour)
      ~U[2024-01-01 12:00:00Z]

  This example puts events into groups by the hour:

      iex> events = [~U[2024-01-01 09:15:00Z], ~U[2024-01-01 09:45:00Z], ~U[2024-01-01 10:05:00Z]]
      iex> events
      ...> |> Enum.group_by(&Shoddy.DateTimes.floor(&1, :hour))
      ...> |> Map.new(fn {hour, group} -> {hour, length(group)} end)
      %{~U[2024-01-01 09:00:00Z] => 2, ~U[2024-01-01 10:00:00Z] => 1}
  """
  @spec floor(t(), unit()) :: t()
  def floor(%DateTime{time_zone: "Etc/UTC"} = value, unit) when unit in @units, do: floor_fields(value, unit)
  def floor(%NaiveDateTime{} = value, unit) when unit in @units, do: floor_fields(value, unit)
  def floor(%Time{} = value, unit) when unit in [:minute, :hour], do: floor_fields(value, unit)

  defp floor_fields(%{microsecond: {_, precision}} = value, :minute),
    do: %{value | second: 0, microsecond: {0, precision}}

  defp floor_fields(value, :hour), do: %{floor_fields(value, :minute) | minute: 0}
  defp floor_fields(value, :day), do: %{floor_fields(value, :hour) | hour: 0}

  @doc """
  Rounds a time value up to the start of a unit.

  The unit is `:minute`, `:hour` or `:day`. If the value is already at the
  start of a unit, this function returns it with no change. Otherwise, it
  returns the start of the next unit. The precision of the fractional second
  stays the same.

  This function compares the full fractional second, also the digits after
  the precision. Thus a value can show as the start of a unit and still round
  up. For example, the field `microsecond: {400, 3}` shows as `.000`, but
  the value is 400 microseconds after the start.

  This function accepts a `NaiveDateTime` and a `DateTime` in the time zone
  `Etc/UTC`, as `floor/2` does. It does not accept a `Time`. A `Time` has no
  day. Thus for a `Time` near the end of the day, the next unit does not
  exist. For a `DateTime` in another time zone, this function raises
  `FunctionClauseError`, for the same reason as `floor/2`.

  Use this function to move a value to the start of a unit, but never to an
  earlier time. An example is an expiry time at the start of an hour.

  For a value at the start of a unit, the result is that value. Thus do not
  use this function for the next run of a job each hour. Also do not use it
  for the end of the unit that contains a value. For these two cases, use
  `next_start/2`.

  ## Examples

      iex> Shoddy.DateTimes.ceil(~U[2024-01-01 12:34:56.789Z], :hour)
      ~U[2024-01-01 13:00:00.000Z]

      iex> Shoddy.DateTimes.ceil(~U[2024-01-01 12:34:56Z], :minute)
      ~U[2024-01-01 12:35:00Z]

      iex> Shoddy.DateTimes.ceil(~N[2024-12-31 00:00:01], :day)
      ~N[2025-01-01 00:00:00]

  A value at the start of the unit stays the same:

      iex> Shoddy.DateTimes.ceil(~U[2024-01-01 12:00:00Z], :hour)
      ~U[2024-01-01 12:00:00Z]

  A fractional second above zero rounds up:

      iex> Shoddy.DateTimes.ceil(~U[2024-01-01 12:00:00.000001Z], :hour)
      ~U[2024-01-01 13:00:00.000000Z]

      iex> Shoddy.DateTimes.ceil(%{~U[2024-01-01 12:00:00.000Z] | microsecond: {400, 3}}, :hour)
      ~U[2024-01-01 13:00:00.000Z]

  This example gives a token a life of at least 30 minutes, and makes it
  expire at the start of an hour:

      iex> ~U[2024-01-01 12:34:56Z]
      ...> |> DateTime.add(30, :minute)
      ...> |> Shoddy.DateTimes.ceil(:hour)
      ~U[2024-01-01 14:00:00Z]
  """
  @spec ceil(value, unit()) :: value when value: DateTime.t() | NaiveDateTime.t()
  def ceil(%DateTime{time_zone: "Etc/UTC"} = value, unit) when unit in @units,
    do: ceil_with(value, unit, &DateTime.add/3)

  def ceil(%NaiveDateTime{} = value, unit) when unit in @units, do: ceil_with(value, unit, &NaiveDateTime.add/3)

  defp ceil_with(value, unit, add) do
    start = floor(value, unit)
    if start == value, do: value, else: add.(start, 1, unit)
  end

  @doc """
  Returns `true` if a value is in the period from `first` to `last`.

  The period includes `first` and excludes `last`. Thus two periods that
  follow each other, such as two days, never contain the same value. The
  function returns `false` if `last` is not after `first`, because such a
  period contains no value.

  The three values must have the same type: `Date`, `Time`, `NaiveDateTime`
  or `DateTime`. The function compares them with the function `compare/2` of
  that module. The operators `<` and `>` compare the fields of two structs,
  so they give a wrong result for these values.

  A `DateTime` can be in any time zone. `DateTime.compare/2` compares the
  points in time, so the three values do not need the same time zone. The
  precision of the fractional second also has no effect.

  ## Examples

      iex> Shoddy.DateTimes.between?(~U[2024-01-01 12:00:00Z], ~U[2024-01-01 00:00:00Z], ~U[2024-01-02 00:00:00Z])
      true

  The period includes the first value and excludes the last value:

      iex> Shoddy.DateTimes.between?(~D[2024-01-01], ~D[2024-01-01], ~D[2024-01-03])
      true

      iex> Shoddy.DateTimes.between?(~D[2024-01-03], ~D[2024-01-01], ~D[2024-01-03])
      false

  The operator `<` gives a wrong result for two dates:

      iex> ~D[2024-02-01] < ~D[2024-01-31]
      true

      iex> Shoddy.DateTimes.between?(~D[2024-02-01], ~D[2024-01-01], ~D[2024-01-31])
      false

  A period with a last value that is not after the first value contains no
  value:

      iex> Shoddy.DateTimes.between?(~T[12:00:00], ~T[13:00:00], ~T[11:00:00])
      false
  """
  @spec between?(value, value, value) :: boolean()
        when value: Date.t() | Time.t() | NaiveDateTime.t() | DateTime.t()
  def between?(%module{} = value, %module{} = first, %module{} = last)
      when module in [Date, Time, NaiveDateTime, DateTime] do
    module.compare(value, first) != :lt and module.compare(value, last) == :lt
  end

  @doc """
  Returns the start of the next unit after a time value.

  The unit is `:minute`, `:hour` or `:day`. The result is always after the
  value, also for a value that is at the start of a unit. It is equal to
  the result of `floor/2`, plus one unit. The precision of the fractional
  second stays the same.

  `ceil/2` is different. It returns a value at the start of a unit with no
  change. Use this function for the next run of a job each hour, and for
  the end of the unit that contains a value.

  This function accepts a `NaiveDateTime` and a `DateTime` in the time zone
  `Etc/UTC`, as `ceil/2` does.

  ## Examples

      iex> Shoddy.DateTimes.next_start(~U[2024-01-01 12:34:56Z], :hour)
      ~U[2024-01-01 13:00:00Z]

  For a value at the start of a unit, the result is the start of the next
  unit:

      iex> Shoddy.DateTimes.next_start(~U[2024-01-01 13:00:00Z], :hour)
      ~U[2024-01-01 14:00:00Z]

      iex> Shoddy.DateTimes.ceil(~U[2024-01-01 13:00:00Z], :hour)
      ~U[2024-01-01 13:00:00Z]

  With `floor/2`, the function gives the period of a day:

      iex> value = ~N[2024-12-31 18:00:00]
      iex> {Shoddy.DateTimes.floor(value, :day), Shoddy.DateTimes.next_start(value, :day)}
      {~N[2024-12-31 00:00:00], ~N[2025-01-01 00:00:00]}
  """
  @spec next_start(value, unit()) :: value when value: DateTime.t() | NaiveDateTime.t()
  def next_start(%DateTime{time_zone: "Etc/UTC"} = value, unit) when unit in @units,
    do: value |> floor(unit) |> DateTime.add(1, unit)

  def next_start(%NaiveDateTime{} = value, unit) when unit in @units,
    do: value |> floor(unit) |> NaiveDateTime.add(1, unit)

  @doc """
  Returns `true` if two periods have a value in common.

  Each period is a tuple `{first, last}`. As for `between?/3`, a period
  includes its first value and excludes its last value. Thus two periods
  that only touch, such as two days that follow each other, do not overlap.
  A period with a last value that is not after its first value contains no
  value, so it overlaps no period.

  The four values must have the same type: `Date`, `Time`, `NaiveDateTime`
  or `DateTime`. A `DateTime` can be in any time zone.

  ## Examples

      iex> Shoddy.DateTimes.overlap?({~T[09:00:00], ~T[11:00:00]}, {~T[10:00:00], ~T[12:00:00]})
      true

      iex> Shoddy.DateTimes.overlap?({~T[09:00:00], ~T[10:00:00]}, {~T[10:00:00], ~T[11:00:00]})
      false

  This example checks two bookings of a room:

      iex> booked = {~D[2024-07-01], ~D[2024-07-04]}
      iex> Shoddy.DateTimes.overlap?(booked, {~D[2024-07-04], ~D[2024-07-06]})
      false
      iex> Shoddy.DateTimes.overlap?(booked, {~D[2024-07-03], ~D[2024-07-05]})
      true
  """
  @spec overlap?({value, value}, {value, value}) :: boolean()
        when value: Date.t() | Time.t() | NaiveDateTime.t() | DateTime.t()
  def overlap?({%module{} = first_a, %module{} = last_a}, {%module{} = first_b, %module{} = last_b})
      when module in [Date, Time, NaiveDateTime, DateTime] do
    before?(module, first_a, last_a) and before?(module, first_b, last_b) and
      before?(module, first_a, last_b) and before?(module, first_b, last_a)
  end

  defp before?(module, left, right), do: module.compare(left, right) == :lt
end
