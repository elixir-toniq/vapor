# Vapor

Loads dynamic configuration at runtime.

## Why Vapor?

Dynamically configuring elixir apps can be hard. There are major
differences between configuring applications with mix and configuring
applications in a release. Vapor wants to make all of that easy by
providing an alternative to mix config for runtime configs. Specifically Vapor can:

  * Find and load configuration from files (JSON, YAML, TOML).
  * Read configuration from environment variables.
  * `.env` file support for easy local development.

## Installing

Add vapor to your mix dependencies:

```elixir
def deps do
  [
    {:vapor, "~> 0.4"},
  ]
end
```

## Example

```elixir
defmodule VaporExample.Config do
  alias Vapor.Provider
  alias Vapor.Provider.{File, Env}

  def load_config do
  end
end

defmodule VaporExample.Application do
  use Application

  def start(_type, _args) do
    providers = [
      %Env{bindings: [db_name: "DB_NAME", port: "PORT"]},
      %File{path: "config.toml", bindings: [kafka_brokers: "kafka.brokers"]},
    ]

    # If values could not be found we raise an exception and halt the boot
    # process
    config = Vapor.load!(providers)

    children = [
       {VaporExampleWeb.Endpoint, port: config.port}
       {VaporExample.Repo, db_name: config.db_name},
       {VaporExample.Kafka, brokers: config.kafka_brokers},
    ]

    opts = [strategy: :one_for_one, name: VaporExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Precedence

Vapor merges the configuration based on the order that the providers are specified.

```elixir
providers = [
  %Dotenv{},
  %File{path: "$HOME/.vapor/config.json", bindings: []},
  %Env{bindings: []},
]
```

Env will have the highest precedence, followed by File, and finally Dotenv.

### Translating config values

Its often useful to translate configuration values into something meaningful
for your application. Vapor provides translation options to allow you to do any
type conversions or data manipulation.

```elixir
providers = [
  %Env{bindings: [db_name: "DB_NAME", port: "PORT"]},
  %File{path: "config.toml", bindings: [kafka_brokers: "kafka.brokers"]},
]

translations = [
  port: fn s -> String.to_integer(s) end,
  kafka_brokers: fn str ->
    str
    |> String.split(",")
    |> Enum.map(fn broker ->
      [host, port] = String.split(broker, ":")
      {host, String.to_integer(port)}
    end)
  end
]

config = Vapor.load(providers, translations)
```

### Reading config files

Config files can be read from a number of different file types including
JSON, TOML, and YAML. Vapor determines which file format to use based on the file extension.

### Overriding application environment

In some cases you may want to overwrite the keys in the application
environment for convenience. While this is generally discouraged it can be
a quick way to adopt Vapor. Before you start your supervision tree you can use
something like this:

```elixir
config = Vapor.load!(providers)

Application.put_env(:my_app, MyApp.Repo, [
  database: config[:database],
  username: config[:database_user],
  password: config[:database_pasword],
  hostname: config[:database_host],
  port: config[:database_port],
])
```

## Providers

There are several built in providers

 - Environment
 - .env files
 - JSON
 - YAML
 - TOML

If you need to create a new provider you can do so with the included
`Vapor.Provider` protocol.

```elixir
defmodule MyApp.DatabaseProvider do
  defstruct [id: nil]

  defimpl Vapor.Provider do
    def load(db_provider) do
    end
  end
end
```

## Why does this exist?

Vapor is intended to be used for the configuration of other runtime dependencies
such as setting the port for `Phoenix.Endpoint` or setting the database url for `Ecto.Repo`.
Vapor is *not* intended for configuration of kernel modules such as `:ssh`. Mix releases
provide a release configuration. But configuring an app in this way still has
problems:

* If configuration ends up in Mix config then its still functioning as a global and is shared across all of your running applications.
* Limited ability to recover from failures while fetching config from external providers.
* Its difficult to layer configuration from different sources.

Vapor is specifically designed to target these use cases.

