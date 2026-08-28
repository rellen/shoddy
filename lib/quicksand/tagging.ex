defmodule Quicksand.Tagging do
  @moduledoc """
  Functions that put values into tagged tuples.

  Elixir and OTP use tagged tuples such as `{:ok, value}` and
  `{:error, reason}` frequently. OTP is the set of standard libraries of the
  Erlang platform. The functions in this module construct these
  tuples. Each function takes the value as the first argument. Thus you can
  use these functions in a pipeline.

  ## Examples

      iex> 42 |> Quicksand.Tagging.ok()
      {:ok, 42}

      iex> "not found" |> Quicksand.Tagging.error()
      {:error, "not found"}

      iex> %{count: 1} |> Quicksand.Tagging.tag(:noreply)
      {:noreply, %{count: 1}}
  """

  @doc """
  Puts a value into an ok tuple.

  ## Examples

      iex> Quicksand.Tagging.ok(42)
      {:ok, 42}

      iex> Quicksand.Tagging.ok("hello")
      {:ok, "hello"}
  """
  @spec ok(value) :: {:ok, value} when value: any()
  def ok(value), do: tag(value, :ok)

  @doc """
  Puts a value into an error tuple.

  ## Examples

      iex> Quicksand.Tagging.error("not found")
      {:error, "not found"}

      iex> Quicksand.Tagging.error(:timeout)
      {:error, :timeout}
  """
  @spec error(value) :: {:error, value} when value: any()
  def error(value), do: tag(value, :error)

  @doc """
  Puts a value into a `:noreply` tuple.

  ## Examples

      iex> Quicksand.Tagging.noreply(%{count: 1})
      {:noreply, %{count: 1}}
  """
  @spec noreply(value) :: {:noreply, value} when value: any()
  def noreply(value), do: tag(value, :noreply)

  @doc """
  Puts a state and a timeout into a `:noreply` tagged tuple of three elements.

  The second argument can also be `:hibernate` or a `{:continue, term}` tuple.

  Use this function in a GenServer callback that returns
  `{:noreply, state, timeout}`.

  ## Examples

      iex> Quicksand.Tagging.noreply(%{count: 1}, 5000)
      {:noreply, %{count: 1}, 5000}

      iex> Quicksand.Tagging.noreply(%{count: 1}, :hibernate)
      {:noreply, %{count: 1}, :hibernate}
  """
  @spec noreply(value, extra) :: {:noreply, value, extra} when value: any(), extra: any()
  def noreply(value, extra), do: tag(value, extra, :noreply)

  @doc """
  Puts a value into a `:cont` tuple.

  Use this function with `Enum.reduce_while/3`.

  ## Examples

      iex> Quicksand.Tagging.cont(0)
      {:cont, 0}
  """
  @spec cont(value) :: {:cont, value} when value: any()
  def cont(value), do: tag(value, :cont)

  @doc """
  Puts a value into a `:halt` tuple.

  Use this function with `Enum.reduce_while/3`.

  ## Examples

      iex> Quicksand.Tagging.halt(42)
      {:halt, 42}
  """
  @spec halt(value) :: {:halt, value} when value: any()
  def halt(value), do: tag(value, :halt)

  @doc """
  Puts a value into a `:reply` tuple.

  ## Examples

      iex> Quicksand.Tagging.reply("hello")
      {:reply, "hello"}
  """
  @spec reply(value) :: {:reply, value} when value: any()
  def reply(value), do: tag(value, :reply)

  @doc """
  Puts a reply and a state into a `:reply` tagged tuple of three elements.

  Use this function in a GenServer `handle_call/3` callback.

  ## Examples

      iex> Quicksand.Tagging.reply(:ok, %{count: 1})
      {:reply, :ok, %{count: 1}}
  """
  @spec reply(value, extra) :: {:reply, value, extra} when value: any(), extra: any()
  def reply(value, extra), do: tag(value, extra, :reply)

  @doc """
  Puts a value into a `:stop` tuple.

  ## Examples

      iex> Quicksand.Tagging.stop(:normal)
      {:stop, :normal}
  """
  @spec stop(value) :: {:stop, value} when value: any()
  def stop(value), do: tag(value, :stop)

  @doc """
  Puts a reason and a state into a `:stop` tagged tuple of three elements.

  Use this function in a GenServer callback that must stop the process.

  ## Examples

      iex> Quicksand.Tagging.stop(:normal, %{count: 1})
      {:stop, :normal, %{count: 1}}
  """
  @spec stop(value, extra) :: {:stop, value, extra} when value: any(), extra: any()
  def stop(value, extra), do: tag(value, extra, :stop)

  @doc """
  Puts a value into a tagged tuple with the given atom tag.

  The tag is the last argument. Thus you can use this function in a pipeline.

  ## Examples

      iex> Quicksand.Tagging.tag(42, :ok)
      {:ok, 42}

      iex> Quicksand.Tagging.tag("hello", :reply)
      {:reply, "hello"}

      iex> 42 |> Quicksand.Tagging.tag(:ok)
      {:ok, 42}
  """
  @spec tag(value, tag) :: {tag, value} when tag: atom(), value: any()
  def tag(value, tag) when is_atom(tag), do: {tag, value}

  @doc """
  Puts two values into a tagged tuple of three elements with the given atom tag.

  The tag is the last argument. Thus you can use this function in a pipeline.

  ## Examples

      iex> Quicksand.Tagging.tag(:ok, %{count: 1}, :reply)
      {:reply, :ok, %{count: 1}}

      iex> Quicksand.Tagging.tag(:normal, %{}, :stop)
      {:stop, :normal, %{}}
  """
  @spec tag(value, extra, tag) :: {tag, value, extra}
        when tag: atom(), value: any(), extra: any()
  def tag(value, extra, tag) when is_atom(tag), do: {tag, value, extra}
end
