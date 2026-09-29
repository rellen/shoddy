defmodule Shoddy.Maps do
  @moduledoc """
  Functions that operate on maps and add to the standard `Map` module.

  Each function takes the map as the first argument, as in the `Map` module.
  Thus you can use these functions in a pipeline:

      %{}
      |> Shoddy.Maps.put_if(:name, params["name"])
      |> Shoddy.Maps.put_if(:email, params["email"])

  The name of this module is `Maps`, in the plural. Thus the alias `Maps`
  does not hide the standard `Map` module.
  """

  @doc """
  Puts a value into a map if the value is truthy.

  A truthy value is a value that is not `nil` and not `false`. A falsy value
  is `nil` or `false`.

  If `value` is falsy, this function returns the map with no change. An entry
  that is already in the map under `key` also stays with no change. This
  function does not replace that entry and does not remove it.

  Use this function to build a map from optional data. The map does not get
  an entry for a field that is absent, and it does not get a `nil` value for
  that field.

  ## Examples

  The function puts a truthy value into the map:

      iex> Shoddy.Maps.put_if(%{}, :name, "Ada")
      %{name: "Ada"}

      iex> Shoddy.Maps.put_if(%{a: 1}, :b, 2)
      %{a: 1, b: 2}

  The function ignores a falsy value:

      iex> Shoddy.Maps.put_if(%{a: 1}, :b, nil)
      %{a: 1}

      iex> Shoddy.Maps.put_if(%{a: 1}, :b, false)
      %{a: 1}

  Only a truthy value replaces an entry that is already in the map:

      iex> Shoddy.Maps.put_if(%{a: 1}, :a, 2)
      %{a: 2}

      iex> Shoddy.Maps.put_if(%{a: 1}, :a, nil)
      %{a: 1}

  In Elixir, zero, an empty collection, and an empty string are truthy. Thus
  the function puts them into the map:

      iex> Shoddy.Maps.put_if(%{}, :count, 0)
      %{count: 0}

      iex> Shoddy.Maps.put_if(%{}, :items, [])
      %{items: []}

      iex> Shoddy.Maps.put_if(%{}, :name, "")
      %{name: ""}

  This example builds a map of optional fields in a pipeline:

      iex> params = %{"name" => "Ada", "email" => nil}
      iex> %{}
      ...> |> Shoddy.Maps.put_if(:name, params["name"])
      ...> |> Shoddy.Maps.put_if(:email, params["email"])
      %{name: "Ada"}
  """
  @spec put_if(map(), key, value) :: map() when key: any(), value: any()
  def put_if(map, key, value) when is_map(map) do
    if value, do: Map.put(map, key, value), else: map
  end

  @doc """
  Puts a value into a map if the value is not `nil`.

  If `value` is `nil`, this function returns the map with no change. An entry
  that is already in the map under `key` also stays with no change.

  This function is different from `put_if/3` for one value only.
  `put_if/3` ignores `false`, but this function puts `false` into the map.
  Use this function for a field that can be `false`, such as a boolean
  option.

  ## Examples

  The function puts a value that is not `nil` into the map:

      iex> Shoddy.Maps.put_present(%{}, :name, "Ada")
      %{name: "Ada"}

      iex> Shoddy.Maps.put_present(%{name: "Ada"}, :subscribed, false)
      %{name: "Ada", subscribed: false}

  The function ignores `nil`:

      iex> Shoddy.Maps.put_present(%{name: "Ada"}, :email, nil)
      %{name: "Ada"}

      iex> Shoddy.Maps.put_present(%{email: "ada@example.com"}, :email, nil)
      %{email: "ada@example.com"}

  This example builds a map of optional fields in a pipeline:

      iex> params = %{"name" => "Ada", "email" => nil, "subscribed" => false}
      iex> %{}
      ...> |> Shoddy.Maps.put_present(:name, params["name"])
      ...> |> Shoddy.Maps.put_present(:email, params["email"])
      ...> |> Shoddy.Maps.put_present(:subscribed, params["subscribed"])
      %{name: "Ada", subscribed: false}
  """
  @spec put_present(map(), key, value) :: map() when key: any(), value: any()
  def put_present(map, key, value) when is_map(map) do
    if is_nil(value), do: map, else: Map.put(map, key, value)
  end
end
