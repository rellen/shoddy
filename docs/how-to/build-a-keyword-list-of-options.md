# Build a keyword list of options

This guide shows how to build the options of a function call from optional
data. The list gets an entry only for an option that has a value. Use the
functions of `Shoddy.Keywords`.

The examples use these options from the caller:

```elixir
opts = [retry: :transient, auth: nil, compressed: false]
```

## Put each option that has a value

Start with the options that always apply. Call `Shoddy.Keywords.put_if/3`
one time for each optional option:

```elixir
[receive_timeout: 5_000]
|> Shoddy.Keywords.put_if(:auth, opts[:auth])
|> Shoddy.Keywords.put_if(:retry, opts[:retry])
#=> [retry: :transient, receive_timeout: 5000]
```

`Shoddy.Keywords.put_if/3` ignores `nil` and `false`. It puts each new entry
at the start of the list.

## Keep an option that can be false

`Shoddy.Keywords.put_if/3` ignores `false`. For an option such as
`compressed: false`, `false` is a value that you must keep. Use
`Shoddy.Keywords.put_present/3`. It ignores only `nil`:

```elixir
[receive_timeout: 5_000]
|> Shoddy.Keywords.put_present(:compressed, opts[:compressed])
|> Shoddy.Keywords.put_present(:auth, opts[:auth])
#=> [compressed: false, receive_timeout: 5000]
```

## Keep a key that occurs more than one time

Both functions call `Keyword.put/3`. That function deletes each entry for
the key before it puts the new entry:

```elixir
Shoddy.Keywords.put_if([where: :a, select: :b, where: :c], :where, :d)
#=> [where: :d, select: :b]
```

Some keyword lists use a key more than one time. An example is a keyword
query of Ecto with more than one `where:` key. For such a list, do not use
these functions. Add the entry with the operator `|` to keep each other
entry:

```elixir
[{:where, :d} | [where: :a, select: :b, where: :c]]
#=> [where: :d, where: :a, select: :b, where: :c]
```

## Remove the options with nil from a list

If the list already exists, use `Shoddy.Keywords.compact/1`. It removes each
entry with `nil`, and it keeps the order and `false`:

```elixir
Shoddy.Keywords.compact(receive_timeout: 5_000, retry: nil, redirect: false)
#=> [receive_timeout: 5_000, redirect: false]
```
