# Toggle elements in a selection

This guide shows how to keep a selection that a user turns on and off, such
as a set of filters in a user interface. Keep the selection in a `MapSet`,
and change it with the functions of `Shoddy.MapSets`.

## Toggle one element

Use `Shoddy.MapSets.toggle/2`. It puts an element that is not a member into
the selection, and it deletes an element that is a member:

```elixir
selected = MapSet.new(["elixir"])

Shoddy.MapSets.toggle(selected, "erlang")
#=> MapSet.new(["elixir", "erlang"])

Shoddy.MapSets.toggle(selected, "elixir")
#=> MapSet.new([])
```

In a Phoenix LiveView, toggle the element in `handle_event/3`:

```elixir
def handle_event("toggle", %{"tag" => tag}, socket) do
  {:noreply, update(socket, :selected, &Shoddy.MapSets.toggle(&1, tag))}
end
```

## Set the membership from a new state

Some events carry the new state of an element, and not a request for a
change. An example is "the flag is now on". Do not toggle for such an
event. The same event can arrive two times, for example after a
reconnection, and the second toggle would delete the element.

Use `Shoddy.MapSets.put_or_delete/3`. With `true`, it puts the element into
the selection. With `false`, it deletes the element:

```elixir
enabled = MapSet.new(["dark_mode"])

enabled
|> Shoddy.MapSets.put_or_delete("beta", true)
|> Shoddy.MapSets.put_or_delete("beta", true)
#=> MapSet.new(["beta", "dark_mode"])

Shoddy.MapSets.put_or_delete(enabled, "dark_mode", false)
#=> MapSet.new([])
```

In a Phoenix LiveView, use the function in `handle_info/2`:

```elixir
def handle_info({:flag_changed, flag, enabled?}, socket) do
  {:noreply, update(socket, :enabled, &Shoddy.MapSets.put_or_delete(&1, flag, enabled?))}
end
```

The third argument must be a boolean. For another value, the function
raises `FunctionClauseError`.

[The design of Shoddy](../explanation/design.md#a-new-state-is-not-a-toggle)
tells why the function does not accept each truthy value.

## Toggle each element of a list

Use `Shoddy.MapSets.toggle_all/2`. It toggles each element of the list one
time, also if the list contains the element more than one time:

```elixir
selected = MapSet.new(["elixir"])

Shoddy.MapSets.toggle_all(selected, ["elixir", "gleam"])
#=> MapSet.new(["gleam"])
```

Do not give a list to `Shoddy.MapSets.toggle/2`. That function toggles the
list as one element:

```elixir
Shoddy.MapSets.toggle(selected, ["elixir", "gleam"])
#=> MapSet.new([["elixir", "gleam"], "elixir"])
```

## Select or clear a group

A button such as "Select all" must not toggle. After a click, each element
of the group must be a member, also an element that was a member before.
Use `MapSet.union/2` for this button. For a button such as "Clear", use
`MapSet.difference/2`:

```elixir
selected = MapSet.new(["elixir"])
group = MapSet.new(["elixir", "gleam"])

MapSet.union(selected, group)
#=> MapSet.new(["elixir", "gleam"])

MapSet.difference(selected, group)
#=> MapSet.new([])
```

## Keep the order of the selection

A `MapSet` has no order. If the order of the selection is important, keep a
list, and use `Shoddy.Lists.toggle/2`. It adds a new element at the end:

```elixir
[:name, :email]
|> Shoddy.Lists.toggle(:age)
|> Shoddy.Lists.toggle(:name)
#=> [:email, :age]
```

## Select the next element of a fixed list

For a list of tabs or a list of servers, use `Shoddy.Lists.cycle_next/2`. It
returns the first element after the last element:

```elixir
tabs = [:inbox, :sent, :drafts]

Shoddy.Lists.cycle_next(tabs, :drafts)
#=> :inbox
```

The current element must be in the list. For another element, the function
raises `ArgumentError`.
