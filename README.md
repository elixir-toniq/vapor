# Vapor

A complete configuration system for dynamic configuration in elixir
applications.

## Why Vapor?

Dynamically configuring elixir apps can be hard. There are major
differences between configuring applications with mix and configuring
applications in a release. Vapor wants to make all of that easy by
providing a complete alternative to mix config. Specifically Vapor can:

  * Find and load configuration from files (JSON, YAML, TOML)
  * Read configuration from environment variables
  * Allow developers to programmatically set config values
  * Watch configuration sources for changes.

## How it works

Vapor is an alternative to mix configs. It runs after your application
boots and should therefor be used for "higher level" configuration. Think
more `Phoenix.Endpoint`, `Ecto`, `Kafka` connections and less `:kernel`.

## Example

```elixir
defmodule VaporExample.Config do
  use Vapor.Config

  def start_link(_args \\ []) do
    opts = [
      app_name: :vapor_example,
      env_prefix: "vapor_example",
      config_name: "config",
      config_paths: [
        ".",
        "$HOME/.vapor_example",
      ],
      remote_config: [
        {:etcd, "http://localhost:40001", "config/vapor_example/config.json"}
      ],
      watch_files: false,
      watch_remote: true,
      override_application_env: true,
    ]

    Vapor.start_link(__MODULE__, opts)
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

### Precedence

Vapor can read configuration from multiple sources and will apply
configuration in this order:

 - explicitly setting values
 - environment
 - config file
 - remote configuration system
 - default

### Reading config files

Config files can be read from a number of different file types including
JSON, TOML, and YAML.

### Setting config values

Occasionally you'll need to set values programatically. You can do that
like so:

```elixir
VaporExample.Config.set("key", "value")
```

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
VaporExample.Config.get_string("config_key")
VaporExample.Config.get_int("config_key")
VaporExample.Config.get_float("config_key")
VaporExample.Config.get_bool("config_key")
```

If you need to read a nested value you can use a `"."` to separate each
level:

```elixir
VaporExample.Config.get_int("my_app.repo.port")
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
      database: Vapor.get_string(config, "my_app.repo.database"),
      username: Vapor.get_string(config, "my_app.repo.username"),
      password: Vapor.get_string(config, "my_app.repo.password"),
      hostname: Vapor.get_string(config, "my_app.repo.hostname"),
      port: Vapor.get_int(config, "my_app.repo.port")
    ])

    :ok 
  end
end
```

## Providers

There are providers for a number of different file types and remote
systems:

 - Environment
 - JSON
 - YAML
 - TOML
 - etcd 
 - Consul
 - Vault

If you need to create a new provider you can do so with the included
`Vapor.Provider` behaviour.

```elixir 
defmodule MyApp.DatabaseProvider do
  @behaviour Vapor.Provider

  def load() do
  end

  def watch() do
  end
end
```
