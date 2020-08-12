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

## Adding configuration plans to modules

Vapor provides a `Vapor.Plan` behaviour. This allows modules to describe a provider
or set of providers.

```elixir
defmodule VaporExample.Kafka do
  @behaviour Vapor.Plan

  @impl Vapor.Plan
  def config_plan do
    %Vapor.Provider.Env{
      bindings: [
        {:brokers, "KAFKA_BROKERS"},
        {:group_id, "KAFKA_CONSUMER_GROUP_ID"},
      ]
    }
  end
end

config = Vapor.load!(VaporExample.Kafka)
```

## Planner DSL

While using the structs directly is a perfectly reasonable option, it can often
be verbose. Vapor provides a DSL for specifying configuration plans using less
lines of code.

```elixir
defmodule VaporExample.Config do
  use Vapor.Planner

  dotenv()

  config :db, env([
    {:url, "DB_URL"},
    {:name, "DB_NAME"},
    {:pool_size, "DB_POOL_SIZE", default: 10, map: &String.to_integer/1},
  ])

  config :web, env([
    {:port, "PORT", map: &String.to_integer/1}
  ])

  config :kafka, VaporExample.Kafka
end

defmodule VaporExample.Application do
  use Application

  def start(_type, _args) do
    config = Vapor.load!(VaporExample.Config)

    children = [
       {VaporExampleWeb.Endpoint, config.web}
       {VaporExample.Repo, config.db},
       {VaporExample.Kafka, config.kafka},
    ]

    opts = [strategy: :one_for_one, name: VaporExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Custom Providers

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
    {:vapor, "~> 0.10"},
  ]
end
```

## Resources from the community

[Configuring your Elixir Application at Runtime with Vapor](https://blog.appsignal.com/2020/04/28/configuring-your-elixir-application-at-runtime-with-vapor.html)
