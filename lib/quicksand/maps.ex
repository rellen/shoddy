defmodule Quicksand.Maps do
  @moduledoc """
  Functions for working with maps that complement the standard `Map` module.

  All functions take the map as the first argument, mirroring `Map` itself, so
  they compose naturally in pipelines:

      %{}
      |> Quicksand.Maps.put_if(:name, params["name"])
      |> Quicksand.Maps.put_if(:email, params["email"])

  Named `Maps` (plural) so it can be aliased as `Maps` alongside the built-in
  `Map` without shadowing it.
  """

  @doc """
  Puts the value into the map, but only when the value is truthy.

  When `value` is falsy (`nil` or `false`), the map is returned unchanged —
  including any existing entry under `key`, which is left as it was rather
  than being overwritten or removed.

  Useful for building maps from optional data, where absent fields should be
  omitted instead of stored as `nil`.

  ## Examples

  Truthy values are put into the map:

      iex> Quicksand.Maps.put_if(%{}, :name, "Ada")
      %{name: "Ada"}

      iex> Quicksand.Maps.put_if(%{a: 1}, :b, 2)
      %{a: 1, b: 2}

  Falsy values are skipped:

      iex> Quicksand.Maps.put_if(%{a: 1}, :b, nil)
      %{a: 1}

      iex> Quicksand.Maps.put_if(%{a: 1}, :b, false)
      %{a: 1}

  An existing entry is overwritten only by a truthy value:

      iex> Quicksand.Maps.put_if(%{a: 1}, :a, 2)
      %{a: 2}

      iex> Quicksand.Maps.put_if(%{a: 1}, :a, nil)
      %{a: 1}

  Zero and empty collections are truthy in Elixir, so they are put:

      iex> Quicksand.Maps.put_if(%{}, :count, 0)
      %{count: 0}

      iex> Quicksand.Maps.put_if(%{}, :items, [])
      %{items: []}

      iex> Quicksand.Maps.put_if(%{}, :name, "")
      %{name: ""}

  Building a map of optional fields in a pipeline:

      iex> params = %{"name" => "Ada", "email" => nil}
      iex> %{}
      ...> |> Quicksand.Maps.put_if(:name, params["name"])
      ...> |> Quicksand.Maps.put_if(:email, params["email"])
      %{name: "Ada"}
  """
  @spec put_if(map(), key, value) :: map() when key: any(), value: any()
  def put_if(map, key, value) when is_map(map) do
    if value, do: Map.put(map, key, value), else: map
  end
end
