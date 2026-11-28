# Write a term into a log

This guide shows how to write a term into a log without the data in the
term. A term is any value of Elixir or Erlang. Use
`Shoddy.Terms.shape/2`.

## Write the shape of a failure

`inspect/1` shows each value of a term. Thus an error tuple can put a name
or an email address into the log:

```elixir
reason = {:invalid, %{"email" => "ada@example.com"}}

inspect(reason)
#=> "{:invalid, %{\"email\" => \"ada@example.com\"}}"
```

`Shoddy.Terms.shape/2` shows the atoms, and only the kind of each other
value:

```elixir
require Logger

reason = {:invalid, %{"email" => "ada@example.com"}}

Shoddy.Terms.shape(reason)
#=> "{:invalid, map(1)}"

Logger.warning("The import failed: #{Shoddy.Terms.shape(reason)}")
```

## Write the shape of an exception

The function shows the module of an exception. It does not show the
message, because a message often contains the value that the code refused:

```elixir
error = %ArgumentError{message: "invalid email: ada@example.com"}

Shoddy.Terms.shape(error)
#=> "ArgumentError"
```

The function also shows the field `:reason` if the field contains an atom:

```elixir
Shoddy.Terms.shape(%File.Error{reason: :enoent, path: "/home/ada/notes.txt"})
#=> "File.Error(reason: :enoent)"
```

## Show other fields of an exception

Give the names of the fields in the option `:fields`. The function shows a
field that contains an atom, a tuple, an exception or a list of exceptions.
It does not show a field with another value:

```elixir
error = %KeyError{key: :email, term: %{"email" => "ada@example.com"}}

Shoddy.Terms.shape(error, fields: [:key, :term])
#=> "KeyError(key: :email)"
```

The function shows each exception of a list, up to five, and the number of
the others. A field of an exception can also contain such a list:

```elixir
errors = [%KeyError{key: :name}, %KeyError{key: :email}]

Shoddy.Terms.shape(errors, fields: [:key])
#=> "[KeyError(key: :name), KeyError(key: :email)]"
```

## Limit the levels

The option `:depth` gives the number of levels of tuples and exceptions that
the function opens. The default is 4:

```elixir
Shoddy.Terms.shape({:a, {:b, {:c, 1}}}, depth: 2)
#=> "{:a, {:b, tuple(2)}}"
```
