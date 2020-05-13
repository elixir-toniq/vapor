# Vapor

<!-- MDOC !-->

Loads dynamic configuration at runtime.

## Why Vapor?

Dynamically configuring elixir apps can be hard. There are major
differences between configuring applications with mix and configuring
applications in a release. Vapor wants to make all of that easy by
providing an alternative to mix config for runtime configs. Specifically Vapor can:

  * Find and load configuration from files (JSON, YAML, TOML).
  * Read configuration from environment variables.
  * `.env` file support for easy local development.

## Example

```elixir
defmodule VaporExample.Application do
  use Application
  alias Vapor.Provider.{File, Env}

  def start(_type, _args) do
    providers = [
      %Env{bindings: [db_url: "DB_URL", db_name: "DB_NAME", port: "PORT"]},
      %File{path: "config.toml", bindings: [kafka_brokers: "kafka.brokers"]},
    ]

    # If values could not be found we raise an exception and halt the boot
    # process
    config = Vapor.load!(providers)

    children = [
       {VaporExampleWeb.Endpoint, port: config.port}
       {VaporExample.Repo, [db_url: config.db_url, db_name: config.db_name]},
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

### Options on bindings

Bindings for `%Env{}` and `%File{}` providers support a number of options:

* `:map` - Allows you to pass a "translation" function with the binding.
* `:default` - If the value is not found then the default value will be returned instead. Defaults always skip the translations.
* `:required` - Marks the binding a required or not required (defaults to true). If required values are missing, and there is no default present, then the provider will return an exception. If the binding is marked `required: false`, then the provider returns the key with a `nil` value.

```elixir
providers = [
  %Env{
    bindings: [
      {:db_name, "DB_NAME"},
      {:db_port, "DB_PORT", default: 4369, map: &String.to_integer/1},
    ]
  }
]
```

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

<!-- MDOC !-->

## Why does this exist?

While its possible to use Elixir's release configuration for some use cases,
release configuration has some issues:

* If configuration ends up in Application config then its still functioning as a global and is shared across all of your running applications.
* Limited ability to recover from failures while fetching config from external providers.
* Its difficult to layer configuration from different sources.

Vapor is designed to solve these problems.

## Installing

Add vapor to your mix dependencies:

```elixir
def deps do
  [
    {:vapor, "~> 0.8"},
  ]
end
```

## Resources from the community

[Configuring your Elixir Application at Runtime with Vapor](https://blog.appsignal.com/2020/04/28/configuring-your-elixir-application-at-runtime-with-vapor.html)
