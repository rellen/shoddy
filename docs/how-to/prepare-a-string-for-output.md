# Prepare a string for output

This guide shows how to hide a secret in a log. It also shows how to make
sure that a string starts or ends with a fixed text. The examples use an
alias:

```elixir
alias Shoddy.Strings
```

## Hide a secret in a log

Use `Shoddy.Strings.mask/2`. By default, it shows only the last four
characters:

```elixir
Strings.mask("4111111111111111")
#=> "************1111"
```

Give the options `:keep_first` and `:keep_last` to show other parts. A key
of an API often starts with a type that is not secret:

```elixir
Strings.mask("sk_live_abcdef", keep_first: 3, keep_last: 2)
#=> "sk_*********ef"
```

The function never shows more than half of the string. For a short string,
such as a code of six digits, it hides each character:

```elixir
Strings.mask("123456")
#=> "******"
```

The result has the same length as the secret. If the length is a secret
too, do not log the value. The option `:char` must be exactly one
grapheme, so that the result keeps that length:

```elixir
Strings.mask("4111111111111111", char: "•")
#=> "••••••••••••1111"
```

## Add a scheme to a URL

Use `Shoddy.Strings.ensure_prefix/2`. It adds the prefix only if the string
does not start with it:

```elixir
Strings.ensure_prefix("example.com", "https://")
#=> "https://example.com"

Strings.ensure_prefix("https://example.com", "https://")
#=> "https://example.com"
```

## Add a slash at the end of a base URL

Use `Shoddy.Strings.ensure_suffix/2`. Then a path that you add later never
gets two slashes and never gets none:

```elixir
"https://example.com/api"
|> Strings.ensure_suffix("/")
|> Kernel.<>("users")
#=> "https://example.com/api/users"
```
