defmodule Quicksand.Tagging do
  @moduledoc """
  Convenience functions for wrapping values in tagged tuples.

  Tagged tuples like `{:ok, value}` and `{:error, reason}` are used extensively
  in Elixir and OTP. This module provides helpers to construct them, which is
  especially useful in pipelines.

  ## Examples

      iex> 42 |> Quicksand.Tagging.ok()
      {:ok, 42}

      iex> "not found" |> Quicksand.Tagging.error()
      {:error, "not found"}

      iex> %{count: 1} |> Quicksand.Tagging.tag(:noreply)
      {:noreply, %{count: 1}}
  """

  @doc """
  Wraps a value in an `:ok` tuple.

  ## Examples

      iex> Quicksand.Tagging.ok(42)
      {:ok, 42}

      iex> Quicksand.Tagging.ok("hello")
      {:ok, "hello"}
  """
  @spec ok(value) :: {:ok, value} when value: any()
  def ok(value), do: tag(value, :ok)

  @doc """
  Wraps a value in an `:error` tuple.

  ## Examples

      iex> Quicksand.Tagging.error("not found")
      {:error, "not found"}

      iex> Quicksand.Tagging.error(:timeout)
      {:error, :timeout}
  """
  @spec error(value) :: {:error, value} when value: any()
  def error(value), do: tag(value, :error)

  @doc """
  Wraps a value in a `:noreply` tuple.

  ## Examples

      iex> Quicksand.Tagging.noreply(%{count: 1})
      {:noreply, %{count: 1}}
  """
  @spec noreply(value) :: {:noreply, value} when value: any()
  def noreply(value), do: tag(value, :noreply)

  @doc """
  Wraps a state and timeout/action in a `:noreply` 3-tuple.

  Useful for GenServer callbacks that return `{:noreply, state, timeout}`.

  ## Examples

      iex> Quicksand.Tagging.noreply(%{count: 1}, 5000)
      {:noreply, %{count: 1}, 5000}

      iex> Quicksand.Tagging.noreply(%{count: 1}, :hibernate)
      {:noreply, %{count: 1}, :hibernate}
  """
  @spec noreply(value, extra) :: {:noreply, value, extra} when value: any(), extra: any()
  def noreply(value, extra), do: tag(value, extra, :noreply)

  @doc """
  Wraps a value in a `:cont` tuple.

  Useful with `Enum.reduce_while/3` and Plug pipelines.

  ## Examples

      iex> Quicksand.Tagging.cont(0)
      {:cont, 0}
  """
  @spec cont(value) :: {:cont, value} when value: any()
  def cont(value), do: tag(value, :cont)

  @doc """
  Wraps a value in a `:halt` tuple.

  Useful with `Enum.reduce_while/3` and Plug pipelines.

  ## Examples

      iex> Quicksand.Tagging.halt(42)
      {:halt, 42}
  """
  @spec halt(value) :: {:halt, value} when value: any()
  def halt(value), do: tag(value, :halt)

  @doc """
  Wraps a value in a `:reply` tuple.

  ## Examples

      iex> Quicksand.Tagging.reply("hello")
      {:reply, "hello"}
  """
  @spec reply(value) :: {:reply, value} when value: any()
  def reply(value), do: tag(value, :reply)

  @doc """
  Wraps a reply and state in a `:reply` 3-tuple.

  Useful for GenServer `handle_call/3` callbacks.

  ## Examples

      iex> Quicksand.Tagging.reply(:ok, %{count: 1})
      {:reply, :ok, %{count: 1}}
  """
  @spec reply(value, extra) :: {:reply, value, extra} when value: any(), extra: any()
  def reply(value, extra), do: tag(value, extra, :reply)

  @doc """
  Wraps a value in a `:stop` tuple.

  ## Examples

      iex> Quicksand.Tagging.stop(:normal)
      {:stop, :normal}
  """
  @spec stop(value) :: {:stop, value} when value: any()
  def stop(value), do: tag(value, :stop)

  @doc """
  Wraps a reason and state in a `:stop` 3-tuple.

  Useful for GenServer callbacks that need to stop the process.

  ## Examples

      iex> Quicksand.Tagging.stop(:normal, %{count: 1})
      {:stop, :normal, %{count: 1}}
  """
  @spec stop(value, extra) :: {:stop, value, extra} when value: any(), extra: any()
  def stop(value, extra), do: tag(value, extra, :stop)

  @doc """
  Wraps a value in a tagged tuple with the given atom tag.

  The tag argument comes last so the function works naturally in pipelines.

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
  Wraps two values in a 3-element tagged tuple with the given atom tag.

  The tag argument comes last so the function works naturally in pipelines.

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
