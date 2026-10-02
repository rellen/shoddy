defmodule Shoddy.Env do
  @moduledoc """
  Functions that read a value from an environment variable, and convert it.

  Use these functions in `config/runtime.exs`. A release reads that file
  when it starts, so the configuration comes from the environment of the
  system:

      config :my_app, MyAppWeb.Endpoint,
        http: [port: Shoddy.Env.integer("PORT", default: 4000, min: 1, max: 65_535)]

      config :my_app, :signups?, Shoddy.Env.boolean("SIGNUPS", default: true)

      config :my_app, :hosts, Shoddy.Env.list("HOSTS", default: ["localhost"])

  Each function raises an exception for a value that is not correct. The
  application then does not start with a wrong configuration, and the
  message tells the name of the variable.

  A blank value is empty or contains only whitespace. A blank value counts
  as an absent variable. A variable that is set to `""` or `" "` thus gets
  the default. For `list/2`, a value without a list element, such as
  `","`, also counts as absent.

  Each function checks its options also if the variable is absent. Thus a
  wrong option raises an exception in each environment, not only where the
  variable is set.

  ## Options

  Each function accepts the option `:default`. The function returns it if
  the variable is absent or blank. The function does not examine the
  default. If you do not give the option, the function raises
  `System.EnvError` for an absent or blank variable.
  """

  alias Shoddy.Parse
  alias Shoddy.Strings

  @doc """
  Reads an integer from an environment variable.

  The value must contain only the integer, as for `Shoddy.Parse.integer/2`.

  ## Options

    * `:default` - The value for an absent or blank variable. Without this
      option, the function raises `System.EnvError` for such a variable.

    * `:min` and `:max` - The range of the integer, as for
      `Shoddy.Parse.integer/2`.

  This function raises `ArgumentError` for a value that is not an integer
  or is not in the range, and for an unknown option.

  ## Examples

      iex> System.put_env("SHODDY_DOC_PORT", "8080")
      iex> Shoddy.Env.integer("SHODDY_DOC_PORT", default: 4000)
      8080

      iex> System.delete_env("SHODDY_DOC_PORT")
      iex> Shoddy.Env.integer("SHODDY_DOC_PORT", default: 4000)
      4000

      iex> System.put_env("SHODDY_DOC_PORT", "eighty")
      iex> Shoddy.Env.integer("SHODDY_DOC_PORT", default: 4000)
      ** (ArgumentError) invalid value for the environment variable "SHODDY_DOC_PORT": "eighty" (:not_an_integer)
  """
  @spec integer(String.t(), keyword()) :: integer() | default when default: any()
  def integer(name, opts \\ []) when is_binary(name) and is_list(opts) do
    opts = Keyword.validate!(opts, [:default, :min, :max])
    read(name, opts, &Parse.integer(&1, Keyword.take(opts, [:min, :max])))
  end

  @doc """
  Reads a boolean from an environment variable.

  The value must be in the lists of `Shoddy.Parse.boolean/2`. By default,
  these lists contain only `"true"` and `"false"`.

  ## Options

    * `:default` - The value for an absent or blank variable. Without this
      option, the function raises `System.EnvError` for such a variable.

    * `:true_values` and `:false_values` - The texts that give `true` and
      `false`, as for `Shoddy.Parse.boolean/2`.

  This function raises `ArgumentError` for a value that is not in the
  lists, and for an unknown option.

  ## Examples

      iex> System.put_env("SHODDY_DOC_DEBUG", "1")
      iex> Shoddy.Env.boolean("SHODDY_DOC_DEBUG", true_values: ["1"], false_values: ["0"])
      true

      iex> System.put_env("SHODDY_DOC_DEBUG", "")
      iex> Shoddy.Env.boolean("SHODDY_DOC_DEBUG", default: false)
      false
  """
  @spec boolean(String.t(), keyword()) :: boolean() | default when default: any()
  def boolean(name, opts \\ []) when is_binary(name) and is_list(opts) do
    opts = Keyword.validate!(opts, [:default, :true_values, :false_values])
    read(name, opts, &Parse.boolean(&1, Keyword.take(opts, [:true_values, :false_values])))
  end

  defp read(name, opts, parse) do
    text = System.get_env(name, "")
    result = parse.(text)

    if result == :absent or Strings.blank?(text),
      do: default!(name, opts),
      else: value!(result, name, text)
  end

  defp default!(name, opts) do
    case Keyword.fetch(opts, :default) do
      {:ok, default} -> default
      :error -> raise System.EnvError, env: name
    end
  end

  defp value!({:ok, value}, _name, _text), do: value

  defp value!({:error, reason}, name, text) do
    raise ArgumentError,
          "invalid value for the environment variable #{inspect(name)}: #{inspect(text)} (#{inspect(reason)})"
  end

  @doc """
  Reads a list of strings from an environment variable.

  The function splits the value at the separator, trims each value, and
  removes each empty value, as `Shoddy.Strings.split_trim/2` does.

  ## Options

    * `:default` - The value for an absent or blank variable. Without this
      option, the function raises `System.EnvError` for such a variable.

    * `:separator` - The string between two values. The default is `","`.

  This function raises `ArgumentError` for an unknown option, and for a
  separator that `Shoddy.Strings.split_trim/2` does not accept.

  ## Examples

      iex> System.put_env("SHODDY_DOC_HOSTS", "a.example.com, b.example.com")
      iex> Shoddy.Env.list("SHODDY_DOC_HOSTS")
      ["a.example.com", "b.example.com"]

      iex> System.delete_env("SHODDY_DOC_HOSTS")
      iex> Shoddy.Env.list("SHODDY_DOC_HOSTS", default: ["localhost"])
      ["localhost"]
  """
  @spec list(String.t(), keyword()) :: [String.t()] | default when default: any()
  def list(name, opts \\ []) when is_binary(name) and is_list(opts) do
    opts = Keyword.validate!(opts, [:default, separator: ","])
    separator = Keyword.fetch!(opts, :separator)

    read(name, opts, fn text ->
      case Strings.split_trim(text, separator) do
        [] -> :absent
        values -> {:ok, values}
      end
    end)
  end
end
