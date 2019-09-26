# Vapor

A complete configuration system for dynamic configuration in elixir
applications.

## Why Vapor?

Dynamically configuring elixir apps can be hard. There are major
differences between configuring applications with mix and configuring
applications in a release. Vapor wants to make all of that easy by
providing an alternative to mix config for runtime configs. Specifically Vapor can:

  * Find and load configuration from files (JSON, YAML, TOML).
  * Read configuration from environment variables.
  * `.env` file support for easy local development.
  * Allow developers to programmatically set config values.
  * Watch configuration sources for changes.
  * Lookup speed is comparable to `Application.get_env/2`.

Vapor provides its own supervision tree that you can add to your
application's supervision tree similar to `Phoenix.Endpoint` or
`Ecto.Repo`. This means that you can start Vapor at any point in your application
lifecycle. But because of this tradeoff Vapor will always be started after the
release and any kernel modules have started.

## Installing

Add vapor to your mix dependencies:

```
def deps do
  [
    {:vapor, "~> 0.2"},
  ]
end
```

## Example

```elixir
defmodule VaporExample.Config do
  use Vapor

  alias Vapor.Config
  alias Vapor.Provider.{File, Env}

  def start_link(_args \\ []) do
    config =
      Config.default()
      |> Config.merge(File.with_name("$HOME/.vapor/config.json"))
      |> Config.merge(Env.with_prefix("APP"))

    Vapor.start_link(__MODULE__, config, name: __MODULE__)
  end
end

defmodule VaporExample.Application do
  use Application

  def start(_type, _args) do
    children = [
       VaporExample.Config,
       VaporExampleWeb.Endpoint,
       VaporExample.Repo,
       VaporExample.Kafka,
    ]

    opts = [strategy: :one_for_one, name: VaporExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Using the system above the app will not boot until vapor can get
a configuration. This can be changed using standard OTP supervision
strategies.

### Startup guarantees

During the init process Vapor will block until the configuration is loaded. If any error is encountered during the initialization step then after a given number of failures Vapor will halt and tell the supervisor to stop. This is important because dependencies will not be able to boot without proper configuration.

### Precedence

Vapor will apply configuration in the order that it is merged. In the example:

```elixir
config =
  Config.default()
  |> Config.merge(Dotenv.default())
  |> Config.merge(File.with_name("$HOME/.vapor/config.json"))
  |> Config.merge(Env.with_prefix("APP"))
```

Env will have the highest precedence, followed by File, and finally Dotenv.

Manually setting a configuration value always take precedence over any other configuration source.

### Reading config files

Config files can be read from a number of different file types including
JSON, TOML, and YAML. Vapor determines which file format to use based on the file extension.

### Setting config values

Occasionally you'll need to set values programatically. You can do that
like so:

```elixir
VaporExample.Config.set("key", "value")
```

Any manual changes to a configuration value will always take precedence over
other configuration changes even if the underlying sources change.

### Watching config files for changes

You can tell Vapor to watch for changes in your various sources. This
allows you to easily change an application by changing your configuration
source. If you need to take actions (such as restarting processes in your
system) when vapor notices a config change you can implement the
`handle_change/2` callback:

```elixir
defmodule VaporExample.Config do
  def handle_change(source, config) do
    # take some action here...
  end
end
```

### Getting config values

There are multiple ways of getting values out of the configuration:

```elixir
VaporExample.Config.get("config_key", as: :string)
VaporExample.Config.get("config_key", as: :int)
VaporExample.Config.get("config_key", as: :float)
VaporExample.Config.get("config_key", as: :bool)
```

If you need to read a nested value you can provide a path to the value
needed like so:

```elixir
VaporExample.Config.get(["my_app", "repo", "port"], as: :int)
```

### Overriding application environment

In some cases you may want to overwrite the keys in the application
environment for convenience. While this is generally discouraged it can be
a quick way to adopt Vapor. To do this automatically you can provide the
`overwrite_application_env: true` option when starting a config. Vapor
will insert values based on the application name. It will convert each key
into an atom and insert the values into application env.

If you would like to do this manually then you can overwrite the init
callback like so:

```elixir
defmodule VaporExample.Config do
  def init(config) do
    Application.put_env(:my_app, MyApp.Repo, [
      database: Vapor.get(config, ["my_app", "repo", "database"], as: :string),
      username: Vapor.get(config, ["my_app", "repo", "username"], as: :string),
      password: Vapor.get(config, ["my_app", "repo", "password"], as: :string),
      hostname: Vapor.get(config, ["my_app", "repo", "hostname"], as: :string),
      port: Vapor.get(config, ["my_app", "repo", "port"], as: :int)
    ])

    :ok
  end
end
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
Vapor is *not* intended for configuration of kernel modules such as `:ssh`.

If you need to configure lower level modules then you should use Distillery's Provider
system. But in my experience most people can get away with configuring most of
their dependencies at runtime.

## Why not just use distillery's providers for everything?

Distillery provides a set of providers for loading runtime configuration *before*
a release is booted. That means its suitable for configuring modules like `:ssh`.
Those providers are very useful however there are still a few limitations that I
need to be able to solve in my daily work:

* If configuration ends up in Mix config then its still functioning as a global and is shared across all of your running applications.
* Providers are only run on boot.
* Limited ability to recover from failures while fetching config from external providers.

Vapor is specifically designed to target all of these use cases.

