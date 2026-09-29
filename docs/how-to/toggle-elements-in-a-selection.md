# Toggle elements in a selection

This guide shows how to keep a selection that a user turns on and off. A set
of filters in a user interface is an example. Keep the selection in a
`MapSet`. Use the functions of `Shoddy.MapSets` to change it.

## Toggle one element

Use `Shoddy.MapSets.toggle/2`. It puts an element that is absent into the
selection, and it deletes an element that is present:

```elixir
selected = MapSet.new(["elixir"])

Shoddy.MapSets.toggle(selected, "erlang")
#=> MapSet.new(["elixir", "erlang"])

Shoddy.MapSets.toggle(selected, "elixir")
#=> MapSet.new([])
```

In a Phoenix LiveView, toggle the element in the event handler:

```elixir
def handle_event("toggle", %{"tag" => tag}, socket) do
  {:noreply, update(socket, :selected, &Shoddy.MapSets.toggle(&1, tag))}
end
```

## Toggle each element of a list

Use `Shoddy.MapSets.toggle_all/2`. It toggles each element of the list one
time:

```elixir
Shoddy.MapSets.toggle_all(MapSet.new(["elixir"]), ["elixir", "gleam"])
#=> MapSet.new(["gleam"])
```

Do not give a list to `Shoddy.MapSets.toggle/2`. That function toggles the
list as one element:

```elixir
Shoddy.MapSets.toggle(MapSet.new(["elixir"]), ["elixir", "gleam"])
#=> MapSet.new([["elixir", "gleam"], "elixir"])
```

## Select or clear a group

A button such as "Select all" must not toggle. It must put each element into
the selection, also an element that is already present. Use `MapSet.union/2`
for this. To clear a group, use `MapSet.difference/2`:

```elixir
group = MapSet.new(["elixir", "gleam"])

MapSet.union(MapSet.new(["elixir"]), group)
#=> MapSet.new(["elixir", "gleam"])

MapSet.difference(MapSet.new(["elixir"]), group)
#=> MapSet.new([])
```
