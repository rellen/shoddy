# Shorten a string for display

This guide shows how to shorten a string to a maximum length. Examples are a
title in a list and a line in a terminal. Use `Shoddy.Strings.truncate/3`.
The examples use an alias:

```elixir
alias Shoddy.Strings
```

## Shorten a string with an ellipsis

Give the maximum number of characters. The result ends in `"…"` if the
function shortens the string:

```elixir
Strings.truncate("The design of Shoddy", 12)
#=> "The design …"

Strings.truncate("Shoddy", 12)
#=> "Shoddy"
```

The ellipsis is part of the length. Thus the result never has more
characters than the maximum.

## Use a different omission

Give the option `:omission`. An empty omission cuts the string with no mark:

```elixir
Strings.truncate("The design of Shoddy", 12, omission: "...")
#=> "The desig..."

Strings.truncate("The design of Shoddy", 12, omission: "")
#=> "The design o"
```

## Shorten text with accents and emoji

The function counts graphemes. A grapheme is a character that a reader sees,
and it can contain more than one code point. Thus the function never cuts a
character in half:

```elixir
Strings.truncate("Größenänderung", 6)
#=> "Größe…"
```

`binary_part/3` counts bytes, so it can cut a character and make a string
that is not valid. `String.slice/3` also counts graphemes, but it does not
add the omission or keep it inside the length.

## Remove the space before the omission

The function does not remove a space at the end of the shortened text. To
remove it, shorten the string with an empty omission. Then trim the result,
and add the omission yourself:

```elixir
"The design of Shoddy"
|> Strings.truncate(11, omission: "")
|> String.trim_trailing()
|> Kernel.<>("…")
#=> "The design…"
```
