# Return a tagged tuple from a callback

This guide shows how to make the tagged tuples that a GenServer callback and
`Enum.reduce_while/3` must return. A tagged tuple is a tuple with an atom as
the first element. The functions of `Shoddy.Tagging` take the value first,
so each function can be the last step of a pipeline.

The examples use a state of `%{count: 1}`.

## Return a new state

Use `Shoddy.Tagging.noreply/1` as the last step:

```elixir
def handle_cast({:add, amount}, state) do
  state
  |> Map.update!(:count, &(&1 + amount))
  |> Shoddy.Tagging.noreply()
end
```

For an amount of 2, the callback returns `{:noreply, %{count: 3}}`.

## Give a timeout or a continue instruction

Use `Shoddy.Tagging.noreply/2`. The second argument is a timeout,
`:hibernate`, or a `{:continue, term}` tuple:

```elixir
Shoddy.Tagging.noreply(state, 5000)
#=> {:noreply, %{count: 1}, 5000}

Shoddy.Tagging.noreply(state, {:continue, :load})
#=> {:noreply, %{count: 1}, {:continue, :load}}
```

## Reply to a call

Use `Shoddy.Tagging.reply/2`. The first argument is the reply, and the
second argument is the state:

```elixir
def handle_call(:count, _from, state) do
  Shoddy.Tagging.reply(state.count, state)
end
```

The callback returns `{:reply, 1, %{count: 1}}`.

## Stop the process

Use `Shoddy.Tagging.stop/2`. The first argument is the reason, and the
second argument is the state:

```elixir
Shoddy.Tagging.stop(:normal, state)
#=> {:stop, :normal, %{count: 1}}
```

## Continue or halt a reduction

`Enum.reduce_while/3` requires a `:cont` tuple or a `:halt` tuple. Use
`Shoddy.Tagging.cont/1` and `Shoddy.Tagging.halt/1`. This example adds
the numbers while the sum stays at 10 or less:

```elixir
Enum.reduce_while([4, 5, 6, 7], 0, fn number, sum ->
  if sum + number > 10 do
    Shoddy.Tagging.halt(sum)
  else
    Shoddy.Tagging.cont(sum + number)
  end
end)
#=> 9
```

## Put a value into an ok tuple

Use `Shoddy.Tagging.ok/1` or `Shoddy.Tagging.error/1` as the last step:

```elixir
"ada"
|> String.upcase()
|> Shoddy.Tagging.ok()
#=> {:ok, "ADA"}
```

## Use a different tag

Use `Shoddy.Tagging.tag/2` for a tag that has no function of its own. The
tag is the last argument:

```elixir
42
|> Shoddy.Tagging.tag(:found)
#=> {:found, 42}
```

`Shoddy.Tagging.tag/3` makes a tagged tuple of three elements in the same
way.
