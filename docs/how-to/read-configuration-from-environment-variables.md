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

If `PORT` is `"8080"`, the port is `8080`. If `PORT` is absent or empty,
the port is `4000`. If `PORT` is `"http"`, the application does not start:

```elixir
Shoddy.Env.integer("PORT", default: 4000)
#=> ** (ArgumentError) invalid value for the environment variable "PORT": "http" (:not_an_integer)
```

## Require a variable

Do not give the option `:default`. For an absent or empty variable, the
function raises `System.EnvError`, as `System.fetch_env!/1` does:

```elixir
Shoddy.Env.integer("POOL_SIZE")
#=> ** (System.EnvError) could not fetch environment variable "POOL_SIZE" because it is not set
```

## Read a feature flag

Use `Shoddy.Env.boolean/2`. By default, it accepts only `"true"` and
`"false"`. Give the options `:true_values` and `:false_values` for other
texts:

```elixir
config :my_app, :signups?,
  Shoddy.Env.boolean("SIGNUPS", default: true, true_values: ["1", "true"], false_values: ["0", "false"])
```

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
another separator.

## Read a string

Use `System.get_env/2` or `System.fetch_env!/1`. A string needs no
conversion.
