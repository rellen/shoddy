defmodule Shoddy.Numbers do
  @moduledoc """
  Functions that operate on numbers, and add to the standard modules
  `Integer` and `Float`.

  The module contains these functions:

  - `ceil_div/2` divides two integers, and rounds the result up. It gives
    the number of pages for a number of items.
  - `clamp/3` keeps a number in a range.
  - `mean/1` returns the mean of a list, or an error for an empty list.
  """

  @doc """
  Divides two integers, and rounds the result up to the next integer.

  Use this function to calculate the number of pages for a number of items,
  or the number of groups of a fixed size.

  `ceil(a / b)` gives the same result for small numbers. But `/` returns a
  float, and a float cannot store each large integer exactly. This function
  uses only integers, so it is correct for each size.

  The divisor must not be zero. For zero, this function raises
  `FunctionClauseError`.

  ## Examples

      iex> Shoddy.Numbers.ceil_div(10, 3)
      4

      iex> Shoddy.Numbers.ceil_div(9, 3)
      3

      iex> Shoddy.Numbers.ceil_div(0, 3)
      0

  The function rounds up, also for a negative result:

      iex> Shoddy.Numbers.ceil_div(-7, 2)
      -3

  A float loses the last digit of a large integer:

      iex> ceil((10 ** 17 + 1) / 1)
      100000000000000000

      iex> Shoddy.Numbers.ceil_div(10 ** 17 + 1, 1)
      100000000000000001
  """
  @spec ceil_div(integer(), integer()) :: integer()
  def ceil_div(dividend, divisor) when is_integer(dividend) and is_integer(divisor) and divisor != 0 do
    -Integer.floor_div(-dividend, divisor)
  end

  @doc """
  Keeps a number in the range from `min` to `max`.

  If `value` is lower than `min`, this function returns `min`. If `value` is
  higher than `max`, it returns `max`. Otherwise, it returns `value` with no
  change.

  The function returns a limit as you give it. Thus `clamp(5, 0, 3.0)`
  returns the float `3.0`.

  This function raises `ArgumentError` if `min` is higher than `max`. Such a
  range contains no number, so the call is a mistake.

  ## Examples

      iex> Shoddy.Numbers.clamp(15, 1, 10)
      10

      iex> Shoddy.Numbers.clamp(-2, 1, 10)
      1

      iex> Shoddy.Numbers.clamp(4, 1, 10)
      4

  Use the function to keep a page number in the range of the pages:

      iex> %{"page" => "99"}
      ...> |> Map.get("page", "1")
      ...> |> Shoddy.Parse.integer()
      ...> |> Shoddy.Result.unwrap(1)
      ...> |> Shoddy.Numbers.clamp(1, 7)
      7
  """
  @spec clamp(number(), number(), number()) :: number()
  def clamp(value, min, max) when is_number(value) and is_number(min) and is_number(max) do
    if min > max do
      raise ArgumentError, "the minimum #{inspect(min)} is higher than the maximum #{inspect(max)}"
    end

    cond do
      value < min -> min
      value > max -> max
      true -> value
    end
  end

  @doc """
  Returns the mean of a list of numbers.

  The result is `{:ok, mean}`, and the mean is always a float. For an empty
  list, the result is `{:error, :empty}`. `Enum.sum(list) / length(list)`
  raises `ArithmeticError` for an empty list, so code must check it first.

  Each element must be a number. For another element, this function raises
  `ArithmeticError`.

  ## Examples

      iex> Shoddy.Numbers.mean([1, 2, 3, 4])
      {:ok, 2.5}

      iex> Shoddy.Numbers.mean([])
      {:error, :empty}

  Use `Shoddy.Result.unwrap/2` for a default:

      iex> [] |> Shoddy.Numbers.mean() |> Shoddy.Result.unwrap(0.0)
      0.0
  """
  @spec mean([number()]) :: {:ok, float()} | {:error, :empty}
  def mean([]), do: {:error, :empty}
  def mean([_ | _] = list), do: {:ok, Enum.sum(list) / length(list)}
end
