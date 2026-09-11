defmodule Quicksand.MapSets do
  @moduledoc """
  Functions that operate on map sets and add to the standard `MapSet` module.

  Each function takes the map set as the first argument. This is the same as
  the `MapSet` module, and it lets you use these functions in a pipeline:

      MapSet.new([:read])
      |> Quicksand.MapSets.toggle(:write)
      |> Quicksand.MapSets.toggle_all([:read, :delete])

  The name of this module is `MapSets`, in the plural. Thus the alias
  `MapSets` does not hide the standard `MapSet` module.
  """

  @doc """
  Toggles the membership of an element in a map set.

  If the element is a member of the map set, this function deletes the
  element. If the element is not a member, this function puts the element
  into the map set. The function changes no other element.

  Two calls with the same element give back a map set that is equal to the
  first map set.

  This function always operates on one element. A list in the second
  argument is one element. It is not a list of elements. To toggle each
  element of a list, use `toggle_all/2`.

  Use this function for a selection that a person switches on and off. An
  example is a set of filters in a user interface.

  This function decides membership in the same manner as `MapSet.member?/2`.
  That function compares two elements with the strict equality operator
  `===/2`. Thus the integer `1` and the float `1.0` are two different
  elements.

  ## Examples

  The function puts an element that is not a member into the map set:

      iex> Quicksand.MapSets.toggle(MapSet.new([:a, :b]), :c)
      MapSet.new([:a, :b, :c])

      iex> Quicksand.MapSets.toggle(MapSet.new(), :a)
      MapSet.new([:a])

  The function deletes an element that is a member:

      iex> Quicksand.MapSets.toggle(MapSet.new([:a, :b]), :a)
      MapSet.new([:b])

      iex> Quicksand.MapSets.toggle(MapSet.new([:a]), :a)
      MapSet.new([])

  Two calls with the same element give back the first map set:

      iex> set = MapSet.new([:a, :b])
      iex> set |> Quicksand.MapSets.toggle(:c) |> Quicksand.MapSets.toggle(:c)
      MapSet.new([:a, :b])

  The function treats a list as one element:

      iex> Quicksand.MapSets.toggle(MapSet.new(), [1, 2])
      MapSet.new([[1, 2]])

      iex> Quicksand.MapSets.toggle(MapSet.new([[1, 2]]), [1, 2])
      MapSet.new([])

  Use the function in a pipeline:

      iex> MapSet.new([:read])
      ...> |> Quicksand.MapSets.toggle(:write)
      ...> |> Quicksand.MapSets.toggle(:read)
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

  This function calls `toggle/2` one time for each element of the list. The
  function starts at the first element of the list. An empty list gives back
  the map set with no change.

  The second argument must be a list. Each element of that list is one
  element of the map set. A list inside that list is thus one element.

  The function toggles an element one time for each occurrence of the
  element in the list. Two occurrences of an element thus give no change.
  For the same reason, two calls with the same list give back a map set that
  is equal to the first map set.

  The order of the elements in the list does not change the result.

  ## Examples

  The function toggles each element of the list:

      iex> Quicksand.MapSets.toggle_all(MapSet.new([:a, :b]), [:b, :c])
      MapSet.new([:a, :c])

      iex> Quicksand.MapSets.toggle_all(MapSet.new(), [:a, :b])
      MapSet.new([:a, :b])

      iex> Quicksand.MapSets.toggle_all(MapSet.new([:a, :b, :c]), [:a, :c])
      MapSet.new([:b])

  An empty list gives back the map set with no change:

      iex> Quicksand.MapSets.toggle_all(MapSet.new([:a]), [])
      MapSet.new([:a])

  The function toggles an element one time for each occurrence in the list:

      iex> Quicksand.MapSets.toggle_all(MapSet.new(), [:a, :a])
      MapSet.new([])

      iex> Quicksand.MapSets.toggle_all(MapSet.new(), [:a, :a, :a])
      MapSet.new([:a])

  A list inside the list is one element:

      iex> Quicksand.MapSets.toggle_all(MapSet.new(), [[1, 2], :a])
      MapSet.new([[1, 2], :a])

  Use the function in a pipeline:

      iex> MapSet.new([:read])
      ...> |> Quicksand.MapSets.toggle(:write)
      ...> |> Quicksand.MapSets.toggle_all([:read, :delete])
      MapSet.new([:delete, :write])
  """
  @spec toggle_all(MapSet.t(element), [new_element]) :: MapSet.t(element | new_element)
        when element: var, new_element: var
  def toggle_all(%MapSet{} = map_set, elements) when is_list(elements) do
    Enum.reduce(elements, map_set, fn element, acc -> toggle(acc, element) end)
  end
end
