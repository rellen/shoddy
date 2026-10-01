defmodule Shoddy.MapSets do
  @moduledoc """
  Functions that operate on map sets and add to the standard `MapSet` module.

  Each function takes the map set as the first argument, as in the `MapSet`
  module. Thus you can use these functions in a pipeline:

      MapSet.new([:read])
      |> Shoddy.MapSets.toggle(:write)
      |> Shoddy.MapSets.toggle_all([:read, :delete])

  The name of this module is `MapSets`, in the plural. Thus the alias
  `MapSets` does not hide the standard `MapSet` module.
  """

  @doc """
  Toggles the membership of an element in a map set.

  If the element is a member of the map set, this function deletes the
  element. If the element is not a member, this function puts the element
  into the map set. The function changes no other element.

  Two calls with the same element return a map set that is equal to the
  initial map set.

  This function always operates on one element. A list in the second
  argument is one element. It is not a list of elements. To toggle each
  element of a list, use `toggle_all/2`.

  Use this function for a selection that a user turns on and off. A set of
  filters in a user interface is an example.

  This function uses `MapSet.member?/2` to find whether the element is a
  member. That function compares two elements with the strict equality
  operator `===/2`. Thus the integer `1` and the float `1.0` are two
  different elements.

  ## Examples

  The function puts an element that is not a member into the map set:

      iex> Shoddy.MapSets.toggle(MapSet.new([:a, :b]), :c)
      MapSet.new([:a, :b, :c])

      iex> Shoddy.MapSets.toggle(MapSet.new(), :a)
      MapSet.new([:a])

  The function deletes an element that is a member:

      iex> Shoddy.MapSets.toggle(MapSet.new([:a, :b]), :a)
      MapSet.new([:b])

      iex> Shoddy.MapSets.toggle(MapSet.new([:a]), :a)
      MapSet.new([])

  Two calls with the same element return the initial map set:

      iex> set = MapSet.new([:a, :b])
      iex> set |> Shoddy.MapSets.toggle(:c) |> Shoddy.MapSets.toggle(:c)
      MapSet.new([:a, :b])

  The function treats a list as one element:

      iex> Shoddy.MapSets.toggle(MapSet.new(), [1, 2])
      MapSet.new([[1, 2]])

      iex> Shoddy.MapSets.toggle(MapSet.new([[1, 2]]), [1, 2])
      MapSet.new([])

  Use the function in a pipeline:

      iex> MapSet.new([:read])
      ...> |> Shoddy.MapSets.toggle(:write)
      ...> |> Shoddy.MapSets.toggle(:read)
      MapSet.new([:write])
  """
  @spec toggle(MapSet.t(element), new_element) :: MapSet.t(element | new_element)
        when element: var, new_element: var
  def toggle(%MapSet{} = map_set, element) do
    if MapSet.member?(map_set, element) do
      MapSet.delete(map_set, element)
    else
      MapSet.put(map_set, element)
    end
  end

  @doc """
  Toggles the membership of each element of a list in a map set.

  This function toggles each different element of the list one time. If an
  element occurs more than one time in the list, the function toggles it one
  time only. If the list is empty, this function returns the map set with no
  change.

  The second argument must be a list. Each element of that list is one
  element of the map set. Thus a list inside that list is one element.

  The result is equal to the result of
  `MapSet.symmetric_difference(map_set, MapSet.new(elements))`. Two calls
  with the same list return a map set that is equal to the initial map set.
  The order of the elements in the list does not change the result.

  To toggle an element one time for each occurrence, for example to apply a
  list of events, call `toggle/2` for each element with `Enum.reduce/3`.

  ## Examples

  The function toggles each element of the list:

      iex> Shoddy.MapSets.toggle_all(MapSet.new([:a, :b]), [:b, :c])
      MapSet.new([:a, :c])

      iex> Shoddy.MapSets.toggle_all(MapSet.new(), [:a, :b])
      MapSet.new([:a, :b])

      iex> Shoddy.MapSets.toggle_all(MapSet.new([:a, :b, :c]), [:a, :c])
      MapSet.new([:b])

  The function returns the map set with no change for an empty list:

      iex> Shoddy.MapSets.toggle_all(MapSet.new([:a]), [])
      MapSet.new([:a])

  The function toggles an element one time, also if it occurs more than one
  time in the list:

      iex> Shoddy.MapSets.toggle_all(MapSet.new(), [:a, :a])
      MapSet.new([:a])

      iex> Shoddy.MapSets.toggle_all(MapSet.new([:a]), [:a, :a, :a])
      MapSet.new([])

  A list inside the list is one element:

      iex> Shoddy.MapSets.toggle_all(MapSet.new(), [[1, 2], :a])
      MapSet.new([[1, 2], :a])

  Use the function in a pipeline:

      iex> MapSet.new([:read])
      ...> |> Shoddy.MapSets.toggle(:write)
      ...> |> Shoddy.MapSets.toggle_all([:read, :delete])
      MapSet.new([:delete, :write])
  """
  @spec toggle_all(MapSet.t(element), [new_element]) :: MapSet.t(element | new_element)
        when element: var, new_element: var
  def toggle_all(%MapSet{} = map_set, elements) when is_list(elements) do
    elements
    |> Enum.uniq()
    |> Enum.reduce(map_set, &toggle(&2, &1))
  end
end
