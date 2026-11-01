# Read configuration from environment variables

This guide shows how to read a setting from an environment variable in
`config/runtime.exs`. Use the functions of `Shoddy.Env`. Each function
converts the text of the variable, and it raises an exception for a value
that is not correct.

## Read a port with a default

Give the option `:default` for a variable that can be absent. Give the
options `:min` and `:max` to check the range:

```elixir
config :my_app, MyAppWeb.Endpoint,
  http: [port: Shoddy.Env.integer("PORT", default: 4000, min: 1, max: 65_535)]
```

If `PORT` is `"8080"`, the port is `8080`. The function removes the
whitespace at the start and at the end, so `" 8080\n"` also gives `8080`.
If `PORT` is absent or blank, the port is `4000`. If `PORT` is `"http"`,
the application does not start:

```elixir
Shoddy.Env.integer("PORT", default: 4000)
#=> ** (ArgumentError) invalid value for the environment variable "PORT": "http" (:not_an_integer)
```

## Require a variable

Do not give the option `:default`. For an absent variable, the function
raises `System.EnvError`, as `System.fetch_env!/1` does:

```elixir
Shoddy.Env.integer("POOL_SIZE")
#=> ** (System.EnvError) could not fetch environment variable "POOL_SIZE" because it is not set
```

For a blank value, the function raises `ArgumentError`, and the message
tells the value. Thus the message does not say that a set variable is not
set:

```elixir
# POOL_SIZE=" "
Shoddy.Env.integer("POOL_SIZE")
#=> ** (ArgumentError) the environment variable "POOL_SIZE" has no value: " "
```

## Read a feature flag

Use `Shoddy.Env.boolean/2`. By default, it accepts only `"true"` and
`"false"`. Give the options `:true_values` and `:false_values` for other
texts:

```elixir
config :my_app, :signups?,
  Shoddy.Env.boolean("SIGNUPS", default: true, true_values: ["on"], false_values: ["off"])
```

## Accept "1" and "0" for a flag

Give the option `digits: true`. The function then also accepts `"1"` for
`true` and `"0"` for `false`:

```elixir
if Shoddy.Env.boolean("PHX_SERVER", default: false, digits: true) do
  config :my_app, MyAppWeb.Endpoint, server: true
end
```

`mix phx.new` writes `if System.get_env("PHX_SERVER") do` for this flag.
That check is wrong for `PHX_SERVER=false`, because each string is truthy.
With `Shoddy.Env.boolean/2`, `"false"` and `"0"` give `false`, and a text
such as `"TRUE"` stops the start.

## Use a default of nil

The function does not examine the default, so `nil` is a correct default.
Use it for a setting that is optional:

```elixir
config :my_app, :max_upload_mb, Shoddy.Env.integer("MAX_UPLOAD_MB", default: nil)
```

## Read a list of values

Use `Shoddy.Env.list/2`, for example for a list of hosts. It splits the value
at each comma, trims each value, and removes each empty value:

```elixir
config :my_app, :hosts, Shoddy.Env.list("HOSTS", default: ["localhost"])
```

For `HOSTS="a.example.com, b.example.com"`, the list is
`["a.example.com", "b.example.com"]`. Give the option `:separator` for
another separator. A value without a list element, such as `","`, is blank.
The function then returns the default, or raises `ArgumentError` without a
default.

## Read a string

Use `Shoddy.Env.string/2`. It trims the value, and it treats a blank value
as an absent value:

```elixir
config :my_app, MyApp.Repo, url: Shoddy.Env.string("DATABASE_URL")

config :my_app, :mail_from_name, Shoddy.Env.string("MAIL_FROM_NAME", default: "Example")
```

Do not use `System.get_env/1` with `|| raise`, or `System.fetch_env!/1`.
These forms accept a variable that is set to `""`, so a blank secret passes
the check.

## Require a minimum size for a secret

Give the option `:min_bytes`. For a shorter value, the application does not
start:

```elixir
config :my_app, MyAppWeb.Endpoint,
  secret_key_base: Shoddy.Env.string("SECRET_KEY_BASE", min_bytes: 64)
```

```elixir
# SECRET_KEY_BASE="short"
Shoddy.Env.string("SECRET_KEY_BASE", min_bytes: 64)
#=> ** (ArgumentError) the environment variable "SECRET_KEY_BASE" has 5 bytes, but it must have at least 64 bytes
```

The message does not contain the value. Plug needs at least 64 bytes for the
secret key base of a cookie store. Without the option, a short key causes an
error only at the first request that uses the session.
