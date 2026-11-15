# Test a process

This guide shows how to wait for a process in an ExUnit test, and how to
change the environment for one test. Use `Shoddy.Tests`. The examples use an
alias:

```elixir
alias Shoddy.Tests
```

## Wait for a condition

A process does its work while the test continues, so the test must wait
for the result. Give a check to `Shoddy.Tests.eventually/2`:

```elixir
{:ok, cache} = Agent.start_link(fn -> %{} end)
Task.start(fn -> Agent.update(cache, &Map.put(&1, :a, 1)) end)

assert Tests.eventually(fn -> Agent.get(cache, &map_size/1) == 1 end)
```

## Wait for the end of a process

`Shoddy.Tests.await_down/2` waits for a process that stops by itself, and
`Shoddy.Tests.kill_and_wait/2` stops a process that has no link to the test:

```elixir
task = spawn(fn -> Process.sleep(20) end)
assert Tests.await_down(task) == :normal

{:ok, worker} = Agent.start(fn -> 0 end)
assert Tests.kill_and_wait(worker) == :killed
```

If the process can stop before the call, accept `:noproc` also.

## Suspend a process

A suspended process does not reply. Use `Shoddy.Tests.suspend/1` to test
what a caller does then:

```elixir
{:ok, worker} = Agent.start_link(fn -> 0 end)
Tests.suspend(worker)

assert {:timeout, _call} = catch_exit(Agent.get(worker, & &1, 10))
```

## Change the environment for one test

`Shoddy.Tests.put_app_env/3` and `Shoddy.Tests.put_system_env/2` change a
value until the end of the test. All tests share the environment, so do not
use `async: true` in the module of such a test:

```elixir
Tests.put_app_env(:my_app, :timeout, 100)
Tests.put_system_env("TZ", "UTC")

{Application.fetch_env!(:my_app, :timeout), System.fetch_env!("TZ")}
#=> {100, "UTC"}
```
