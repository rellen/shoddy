defmodule Shoddy.Keywords do
  @moduledoc """
  Functions that operate on keyword lists and add to the standard `Keyword`
  module.

  Each function takes the keyword list as the first argument, as in the
  `Keyword` module. Thus you can use these functions in a pipeline:

      [receive_timeout: 5_000]
      |> Shoddy.Keywords.put_if(:retry, opts[:retry])
      |> Shoddy.Keywords.put_present(:compressed, opts[:compressed])

  The name of this module is `Keywords`, in the plural. Thus the alias
  `Keywords` does not hide the standard `Keyword` module.

  `put_if/3` and `put_present/3` put a value with `Keyword.put/3`. That
  function deletes each entry for the key, and it puts the new entry at the
  start of the list. Thus a key that occurs more than one time occurs one
  time after the call. If a function does not put the value, the list stays
  with no change, also if it contains a key more than one time.

  `get_present/3` reads a value with `Keyword.get/2`. Thus it reads the
  first entry for the key. `compact/1` removes each entry with the value
  `nil`.
  """

  @doc """
  Puts a value into a keyword list if the value is truthy.

  A truthy value is a value that is not `nil` and not `false`. A falsy value
  is `nil` or `false`.

  If `value` is falsy, this function returns the keyword list with no
  change. If `value` is truthy, this function calls `Keyword.put/3`. That
  function deletes each entry for `key` and puts the new entry at the start
  of the list.

  Use this function to build the options of a function call from optional
  data. The list does not get an entry for an absent option.

  ## Examples

  The function puts a truthy value into the list:

      iex> Shoddy.Keywords.put_if([], :timeout, 5_000)
      [timeout: 5_000]

      iex> Shoddy.Keywords.put_if([retry: false], :timeout, 5_000)
      [timeout: 5_000, retry: false]

  The function ignores a falsy value:

      iex> Shoddy.Keywords.put_if([retry: false], :timeout, nil)
      [retry: false]

      iex> Shoddy.Keywords.put_if([retry: false], :timeout, false)
      [retry: false]

  A truthy value replaces each entry for the key:

      iex> Shoddy.Keywords.put_if([timeout: 1, retry: false, timeout: 2], :timeout, 3)
      [timeout: 3, retry: false]

  This example builds the options of a function call in a pipeline:

      iex> opts = [retry: :transient]
      iex> [receive_timeout: 5_000]
      ...> |> Shoddy.Keywords.put_if(:retry, opts[:retry])
      ...> |> Shoddy.Keywords.put_if(:auth, opts[:auth])
      [retry: :transient, receive_timeout: 5_000]
  """
  @spec put_if(keyword(), atom(), value) :: keyword() when value: any()
  def put_if(keywords, key, value) when is_list(keywords) and is_atom(key) do
    if value, do: Keyword.put(keywords, key, value), else: keywords
  end

  @doc """
  Puts a value into a keyword list if the value is not `nil`.

  If `value` is `nil`, this function returns the keyword list with no change.
  For another value, this function calls `Keyword.put/3`. That function
  deletes each entry for `key` and puts the new entry at the start of the
  list.

  This function is different from `put_if/3` for one value only. `put_if/3`
  ignores `false`, but this function puts `false` into the list. Use this
  function for an option that can be `false`.

  ## Examples

  The function puts a value that is not `nil` into the list:

      iex> Shoddy.Keywords.put_present([], :compressed, false)
      [compressed: false]

      iex> Shoddy.Keywords.put_present([timeout: 5_000], :retry, :transient)
      [retry: :transient, timeout: 5_000]

  The function ignores `nil`:

      iex> Shoddy.Keywords.put_present([timeout: 5_000], :retry, nil)
      [timeout: 5_000]

  A value that is not `nil` replaces each entry for the key:

      iex> Shoddy.Keywords.put_present([compressed: true, compressed: true], :compressed, false)
      [compressed: false]
  """
  @spec put_present(keyword(), atom(), value) :: keyword() when value: any()
  def put_present(keywords, key, value) when is_list(keywords) and is_atom(key) do
    if is_nil(value), do: keywords, else: Keyword.put(keywords, key, value)
  end

  @doc """
  Returns the value of a key, or a default if the value is absent or `nil`.

  This function reads the first entry for `key`, as `Keyword.get/2` does. If
  the list has no entry for `key`, or the value of the first entry is `nil`,
  this function returns `default`. It returns `false` with no change.

  `Keyword.get(keywords, key, default)` is different. It returns `nil` for an
  entry with the value `nil`. `Keyword.get(keywords, key) || default` is also
  different. It returns the default also for `false`.

  ## Examples

      iex> Shoddy.Keywords.get_present([timeout: 5_000], :timeout, 1_000)
      5_000

      iex> Shoddy.Keywords.get_present([], :timeout, 1_000)
      1_000

      iex> Shoddy.Keywords.get_present([timeout: nil], :timeout, 1_000)
      1_000

  The function returns `false` with no change:

      iex> Shoddy.Keywords.get_present([retry: false], :retry, true)
      false

  The first entry for the key decides:

      iex> Shoddy.Keywords.get_present([timeout: nil, timeout: 5_000], :timeout, 1_000)
      1_000
  """
  @spec get_present(keyword(), atom(), default) :: value | default when value: any(), default: any()
  def get_present(keywords, key, default) when is_list(keywords) and is_atom(key) do
    case Keyword.get(keywords, key) do
      nil -> default
      value -> value
    end
  end

  @doc """
  Removes each entry with the value `nil`.

  Use this function before you give options to a library that treats `nil` as
  a value. The function keeps the order of the entries, and it keeps a key
  that occurs more than one time. It keeps `false`.

  ## Examples

      iex> Shoddy.Keywords.compact(timeout: 5_000, retry: nil, follow: false)
      [timeout: 5_000, follow: false]

      iex> Shoddy.Keywords.compact(header: "a", header: nil, header: "b")
      [header: "a", header: "b"]
  """
  @spec compact(keyword()) :: keyword()
  def compact(keywords) when is_list(keywords), do: Keyword.reject(keywords, fn {_key, value} -> is_nil(value) end)
end
