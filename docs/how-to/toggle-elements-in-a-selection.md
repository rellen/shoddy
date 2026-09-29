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

## Toggle each element of a list

Use `Shoddy.MapSets.toggle_all/2`. It toggles each element of the list one
time:

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
