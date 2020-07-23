defmodule Vapor.Provider.Group do
  @moduledoc """
  Allows users to group together bits of configuration. This allows users to
  avoid duplication and avoids conflicts in common names such as "port" and
  "host".

  ## Example

  ```elixir
  providers = [
    %Group{
      name: :primary_db,
      providers: [
        %Env{bindings: [port: "PRIMARY_DB_PORT", host: "PRIMARY_DB_HOST"]},
      ]
    },
    %Group{
      name: :redis,
      providers: [
        %Env{bindings: [port: "REDIS_PORT", host: "REDIS_HOST"]},
      ]
    },
  ]
  ```
  """
  defstruct providers: [], name: nil

  defimpl Vapor.Provider do
    def load(%{providers: providers, name: name}) do
      with {:ok, config} <- Vapor.Loader.load(providers) do
        {:ok, Map.put(Map.new(), name, Map.new(config))}
      end
    end
  end
end
