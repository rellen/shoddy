defmodule Shoddy.Tests do
  @moduledoc """
  Functions for ExUnit tests of processes and of the environment.

  The functions need ExUnit, which is the test framework of Elixir. Thus use
  this module only in a test.

  `suspend/1`, `put_app_env/3` and `put_system_env/2` call
  `ExUnit.Callbacks.on_exit/1`. Thus the caller must be the test process. A
  `setup` callback also runs in the test process.
  """

  @doc """
  Calls a function of arity 0 until it returns a truthy value.

  The result is the first truthy value. After the time limit, the result is
  `false`. Thus a test can give the result to `assert`.

  The option `:timeout` is the time limit in milliseconds, and its default is
  100. The option `:interval` is the time between two calls in milliseconds,
  and its default is 10. The last call occurs at the time limit, so a timeout
  of 0 gives exactly one call.

  ## Examples

      iex> Shoddy.Tests.eventually(fn -> 1 + 1 end)
      2

      iex> Shoddy.Tests.eventually(fn -> nil end, timeout: 20, interval: 5)
      false
  """
  @spec eventually((-> value), keyword()) :: value | false when value: any()
  def eventually(fun, opts \\ []) when is_function(fun, 0) and is_list(opts) do
    opts = Keyword.validate!(opts, timeout: 100, interval: 10)
    timeout = timeout!(opts)
    interval = interval!(opts)

    poll(fun, System.monotonic_time(:millisecond) + timeout, interval)
  end

  defp timeout!(opts) do
    case Keyword.fetch!(opts, :timeout) do
      timeout when is_integer(timeout) and timeout >= 0 -> timeout
      other -> Shoddy.Option.invalid!(:timeout, "a non-negative integer", other)
    end
  end

  defp interval!(opts) do
    case Keyword.fetch!(opts, :interval) do
      interval when is_integer(interval) and interval > 0 -> interval
      other -> Shoddy.Option.invalid!(:interval, "a positive integer", other)
    end
  end

  defp poll(fun, deadline, interval) do
    value = fun.()
    time_left = deadline - System.monotonic_time(:millisecond)

    cond do
      value ->
        value

      time_left <= 0 ->
        false

      true ->
        Process.sleep(min(interval, time_left))
        poll(fun, deadline, interval)
    end
  end

  @doc """
  Waits until a process stops, and returns its exit reason.

  The timeout is a number of milliseconds. After the timeout, the function
  raises `ExUnit.AssertionError`. For a process that stopped before the
  call, the function returns `:noproc`.

  ## Examples

      pid = spawn(fn -> Process.sleep(20) end)

      Shoddy.Tests.await_down(pid)
      #=> :normal
  """
  @spec await_down(pid(), non_neg_integer()) :: term()
  def await_down(pid, timeout \\ 100) when is_pid(pid) and is_integer(timeout) and timeout >= 0 do
    pid |> Process.monitor() |> await_down(pid, timeout)
  end

  defp await_down(ref, pid, timeout) do
    receive do
      {:DOWN, ^ref, :process, ^pid, reason} -> reason
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        raise ExUnit.AssertionError, message: "the process #{inspect(pid)} did not stop in #{timeout} milliseconds"
    end
  end

  @doc """
  Kills a process, and waits until it stops.

  The function sends the exit signal `:kill`. Then it waits as
  `await_down/2` does, with the same timeout and the same results. The exit
  reason is `:killed` for a process that was alive.

  The function does not remove a link between the process and the caller.
  Thus a process with such a link also stops the caller, unless the caller
  traps exits with `Process.flag/2`. Call `Process.unlink/1` first for such
  a process.

  ## Examples

      pid = spawn(fn -> Process.sleep(:infinity) end)

      Shoddy.Tests.kill_and_wait(pid)
      #=> :killed
  """
  @spec kill_and_wait(pid(), non_neg_integer()) :: term()
  def kill_and_wait(pid, timeout \\ 100) when is_pid(pid) and is_integer(timeout) and timeout >= 0 do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    await_down(ref, pid, timeout)
  end

  @doc """
  Suspends a process until the end of the test.

  The function calls `:sys.suspend/1`. A suspended process handles only the
  messages of the module `:sys`, and it keeps each other message in its
  mailbox. At the end of the test, also of a test that fails,
  `:sys.resume/1` resumes the process.

  ## Examples

      {:ok, worker} = Agent.start_link(fn -> 0 end)

      Shoddy.Tests.suspend(worker)
      #=> :ok
  """
  @spec suspend(pid()) :: :ok
  def suspend(pid) when is_pid(pid) do
    ExUnit.Callbacks.on_exit(fn -> resume(pid) end)
    :sys.suspend(pid)
  end

  # A process that stopped before the end of the test makes `:sys.resume/1`
  # exit.
  defp resume(pid) do
    :sys.resume(pid)
  catch
    :exit, _reason -> :ok
  end

  @doc """
  Puts a value into the application environment until the end of the test.

  The function calls `Application.put_env/3`. At the end of the test, it
  restores the old value. If the key had no value, it deletes the key.

  ## Examples

      Shoddy.Tests.put_app_env(:my_app, :timeout, 100)
      #=> :ok
  """
  @spec put_app_env(atom(), atom(), term()) :: :ok
  def put_app_env(app, key, value) when is_atom(app) and is_atom(key) do
    old = Application.fetch_env(app, key)
    ExUnit.Callbacks.on_exit(fn -> restore_app_env(app, key, old) end)
    Application.put_env(app, key, value)
  end

  defp restore_app_env(app, key, {:ok, value}), do: Application.put_env(app, key, value)
  defp restore_app_env(app, key, :error), do: Application.delete_env(app, key)

  @doc """
  Sets an environment variable until the end of the test.

  The function calls `System.put_env/2`. At the end of the test, it restores
  the old value. If the variable was absent, it deletes the variable.

  ## Examples

      Shoddy.Tests.put_system_env("TZ", "UTC")
      #=> :ok
  """
  @spec put_system_env(String.t(), String.t()) :: :ok
  def put_system_env(name, value) when is_binary(name) and is_binary(value) do
    old = System.fetch_env(name)
    ExUnit.Callbacks.on_exit(fn -> restore_system_env(name, old) end)
    System.put_env(name, value)
  end

  defp restore_system_env(name, {:ok, value}), do: System.put_env(name, value)
  defp restore_system_env(name, :error), do: System.delete_env(name)
end
