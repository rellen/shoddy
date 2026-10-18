defmodule Shoddy.Option do
  @moduledoc false

  # The functions of Shoddy raise this error for an option value of the wrong
  # form. One function keeps the message the same in each module.

  @doc false
  @spec invalid!(atom(), String.t(), term()) :: no_return()
  def invalid!(name, expected, value) do
    raise ArgumentError, "invalid value for #{inspect(name)} option: expected #{expected}, got: #{inspect(value)}"
  end
end
