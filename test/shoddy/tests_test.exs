defmodule Shoddy.TestsTest do
  # No other test file uses the application `:shoddy_tests_test` or a variable
  # with the prefix `SHODDY_TESTS_TEST_`. Thus `async: true` is safe.
  use ExUnit.Case, async: true

  import Shoddy.Tests

  doctest Shoddy.Tests

  @app :shoddy_tests_test

  # ExUnit runs the callbacks of `on_exit/1` in the reverse order, but its
  # documentation does not give the order. Thus a test registers its check
  # before it calls the function under test. The check then runs after the
  # callback of that function. If ExUnit runs the callbacks in another order,
  # the check fails. A test cannot pass because of a wrong order.

  defp start_sleeper do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    on_exit(fn -> Process.exit(pid, :kill) end)
    pid
  end

  defp start_stopped do
    {pid, ref} = spawn_monitor(fn -> :ok end)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 5000
    pid
  end

  defp start_agent do
    {:ok, agent} = Agent.start(fn -> 0 end)
    agent
  end

  defp sys_state(pid) do
    {:status, ^pid, _module, [_dictionary, state | _rest]} = :sys.get_status(pid)
    state
  end

  # Sends the reason to the process only after the test process monitors it.
  # Thus the process cannot stop before the call of the function under test.
  defp stop_when_monitored(pid, reason) do
    test_pid = self()

    spawn(fn ->
      eventually(fn -> Process.info(pid, :monitored_by) == {:monitored_by, [test_pid]} end, timeout: 5000, interval: 1)
      send(pid, reason)
    end)
  end

  defp in_other_process(fun) do
    Task.await(Task.async(fn -> catch_error(fun.()) end))
  end

  defp now, do: System.monotonic_time(:millisecond)

  # Returns a function that counts its calls. The function returns a falsy
  # value until the call with the number `truthy_at`.
  defp counted(truthy_at) do
    counter = :counters.new(1, [])

    fun = fn ->
      :counters.add(counter, 1, 1)
      if :counters.get(counter, 1) >= truthy_at, do: {:call, :counters.get(counter, 1)}
    end

    {fun, fn -> :counters.get(counter, 1) end}
  end

  describe "eventually/2" do
    test "returns the first truthy value, and then calls the function no more" do
      {fun, count} = counted(3)

      assert eventually(fun, timeout: 5000, interval: 1) == {:call, 3}
      assert count.() == 3
    end

    test "returns false after the time limit, also for nil" do
      start = now()

      assert eventually(fn -> nil end, timeout: 30, interval: 5) === false
      assert now() - start >= 30
    end

    test "calls the function one time for a timeout of 0" do
      {fun, count} = counted(2)

      assert eventually(fun, timeout: 0) === false
      assert count.() == 1
    end

    test "calls the function a last time at the time limit" do
      {fun, count} = counted(100)
      start = now()

      assert eventually(fun, timeout: 200, interval: 60_000) === false
      assert count.() == 2
      assert now() - start >= 200
    end

    test "waits for the interval between two calls" do
      {fun, _count} = counted(3)
      start = now()

      assert eventually(fun, timeout: 5000, interval: 20)
      assert now() - start >= 40
    end

    test "raises ArgumentError for a wrong option before the first call" do
      fun = fn -> send(self(), :called) end

      assert_raise ArgumentError, ~r/unknown keys \[:attempts\]/, fn -> eventually(fun, attempts: 3) end

      for timeout <- [-1, 1.5, :infinity] do
        assert_raise ArgumentError, ~r/:timeout option: expected a non-negative integer/, fn ->
          eventually(fun, timeout: timeout)
        end
      end

      for interval <- [0, -1, 1.5] do
        assert_raise ArgumentError, ~r/:interval option: expected a positive integer/, fn ->
          eventually(fun, interval: interval)
        end
      end

      refute_received :called
    end

    test "raises FunctionClauseError for an argument of the wrong type" do
      assert_raise FunctionClauseError, fn -> apply(&eventually/2, [fn _value -> true end, []]) end
      assert_raise FunctionClauseError, fn -> apply(&eventually/2, [fn -> true end, %{}]) end
    end
  end

  describe "await_down/2" do
    test "returns the exit reason of a process that stops" do
      for reason <- [:normal, :done] do
        pid = spawn(fn -> receive(do: (reason -> exit(reason))) end)
        stop_when_monitored(pid, reason)

        assert await_down(pid, 5000) == reason
      end
    end

    test "returns :noproc for a process that stopped before the call" do
      assert await_down(start_stopped()) == :noproc
    end

    test "raises ExUnit.AssertionError after the timeout, and removes its monitor" do
      pid = start_sleeper()
      error = assert_raise ExUnit.AssertionError, fn -> await_down(pid, 10) end

      assert error.message == "the process #{inspect(pid)} did not stop in 10 milliseconds"
      assert_raise ExUnit.AssertionError, fn -> await_down(pid, 0) end
      assert Process.info(self(), :monitors) == {:monitors, []}
    end

    test "keeps each other message in the mailbox" do
      send(self(), :other)

      assert await_down(start_stopped()) == :noproc
      assert_received :other
    end

    test "raises FunctionClauseError for an argument of the wrong type" do
      assert_raise FunctionClauseError, fn -> apply(&await_down/1, [:name]) end
      assert_raise FunctionClauseError, fn -> apply(&await_down/2, [self(), -1]) end
      assert_raise FunctionClauseError, fn -> apply(&await_down/2, [self(), :infinity]) end
    end
  end

  describe "kill_and_wait/2" do
    test "kills a process, and returns :killed" do
      pid = start_sleeper()

      assert kill_and_wait(pid) == :killed
      refute Process.alive?(pid)
      assert Process.info(self(), :monitors) == {:monitors, []}
    end

    test "returns :noproc for a process that stopped before the call" do
      assert kill_and_wait(start_stopped()) == :noproc
    end

    test "keeps the link, so a caller that traps exits gets the exit message" do
      Process.flag(:trap_exit, true)
      pid = spawn_link(fn -> Process.sleep(:infinity) end)

      assert kill_and_wait(pid) == :killed
      assert_receive {:EXIT, ^pid, :killed}, 5000
    end

    test "stops a caller that has a link to the process and does not trap exits" do
      caller =
        spawn(fn ->
          pid = spawn_link(fn -> Process.sleep(:infinity) end)
          kill_and_wait(pid, 5000)
          Process.sleep(:infinity)
        end)

      assert await_down(caller, 5000) == :killed
    end

    test "raises FunctionClauseError for an argument of the wrong type" do
      assert_raise FunctionClauseError, fn -> apply(&kill_and_wait/1, [:name]) end
      assert_raise FunctionClauseError, fn -> apply(&kill_and_wait/2, [self(), -1]) end
      assert_raise FunctionClauseError, fn -> apply(&kill_and_wait/2, [self(), 1.5]) end
    end
  end

  describe "suspend/1" do
    test "suspends the process, and resumes it after the test" do
      agent = start_agent()

      on_exit(fn ->
        assert sys_state(agent) == :running
        Agent.stop(agent)
      end)

      assert suspend(agent) == :ok
      assert sys_state(agent) == :suspended
    end

    test "does not fail for a process that stopped before the end of the test" do
      agent = start_agent()

      assert suspend(agent) == :ok
      assert kill_and_wait(agent) == :killed
    end

    test "raises ArgumentError, and does not suspend, for a caller that is not the test process" do
      agent = start_agent()
      on_exit(fn -> Agent.stop(agent) end)

      assert %ArgumentError{} = in_other_process(fn -> suspend(agent) end)
      assert sys_state(agent) == :running
    end

    test "raises FunctionClauseError for a value that is not a pid" do
      assert_raise FunctionClauseError, fn -> apply(&suspend/1, [:name]) end
    end
  end

  describe "put_app_env/3" do
    test "puts the value, and deletes a key that was absent after the test" do
      on_exit(fn -> assert Application.fetch_env(@app, :absent) == :error end)

      assert put_app_env(@app, :absent, 1) == :ok
      assert Application.fetch_env(@app, :absent) == {:ok, 1}
    end

    test "restores the old value after the test" do
      Application.put_env(@app, :present, :old)

      on_exit(fn ->
        assert Application.fetch_env(@app, :present) == {:ok, :old}
        Application.delete_env(@app, :present)
      end)

      put_app_env(@app, :present, :new)
      assert Application.fetch_env(@app, :present) == {:ok, :new}
    end

    test "restores the old value nil, and does not delete the key" do
      Application.put_env(@app, :nil_value, nil)

      on_exit(fn ->
        assert Application.fetch_env(@app, :nil_value) == {:ok, nil}
        Application.delete_env(@app, :nil_value)
      end)

      put_app_env(@app, :nil_value, 1)
    end

    test "restores the first state after two calls for one key" do
      on_exit(fn -> assert Application.fetch_env(@app, :two_calls) == :error end)

      put_app_env(@app, :two_calls, 1)
      put_app_env(@app, :two_calls, 2)
      assert Application.fetch_env(@app, :two_calls) == {:ok, 2}
    end

    test "raises ArgumentError, and puts no value, for a caller that is not the test process" do
      assert %ArgumentError{} = in_other_process(fn -> put_app_env(@app, :other_process, 1) end)
      assert Application.fetch_env(@app, :other_process) == :error
    end

    test "raises FunctionClauseError from put_app_env/3 itself for an argument of the wrong type" do
      error = assert_raise FunctionClauseError, fn -> apply(&put_app_env/3, ["app", :key, 1]) end
      assert error.function == :put_app_env
      error = assert_raise FunctionClauseError, fn -> apply(&put_app_env/3, [@app, "key", 1]) end
      assert error.function == :put_app_env
    end
  end

  describe "put_system_env/2" do
    test "sets the variable, and deletes a variable that was absent after the test" do
      name = "SHODDY_TESTS_TEST_ABSENT"
      on_exit(fn -> assert System.fetch_env(name) == :error end)

      assert put_system_env(name, "1") == :ok
      assert System.fetch_env(name) == {:ok, "1"}
    end

    test "restores the old value after the test" do
      name = "SHODDY_TESTS_TEST_PRESENT"
      System.put_env(name, "old")

      on_exit(fn ->
        assert System.fetch_env(name) == {:ok, "old"}
        System.delete_env(name)
      end)

      put_system_env(name, "new")
      assert System.fetch_env(name) == {:ok, "new"}
    end

    test "restores the first state after two calls for one variable" do
      name = "SHODDY_TESTS_TEST_TWO_CALLS"
      on_exit(fn -> assert System.fetch_env(name) == :error end)

      put_system_env(name, "1")
      put_system_env(name, "2")
      assert System.fetch_env(name) == {:ok, "2"}
    end

    test "raises ArgumentError, and sets no variable, for a caller that is not the test process" do
      name = "SHODDY_TESTS_TEST_OTHER_PROCESS"

      assert %ArgumentError{} = in_other_process(fn -> put_system_env(name, "1") end)
      assert System.fetch_env(name) == :error
    end

    test "raises FunctionClauseError from put_system_env/2 itself for an argument of the wrong type" do
      error = assert_raise FunctionClauseError, fn -> apply(&put_system_env/2, [:name, "1"]) end
      assert error.function == :put_system_env
      error = assert_raise FunctionClauseError, fn -> apply(&put_system_env/2, ["SHODDY_TESTS_TEST_TYPE", 1]) end
      assert error.function == :put_system_env
    end
  end
end
