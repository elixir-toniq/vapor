defmodule Vapor.Provider.Env do
  @moduledoc """
  The Env config module provides support for pulling configuration values
  from the environment. Bindings must be specified at a keyword list.

  ## Example

      %Env{bindings: [foo: "FOO", bar: "VAR_BAR"]}
  """

  defstruct bindings: [], required: true

  @type bindings :: Keyword.t(String.t())

  defimpl Vapor.Provider do
    def load(%{bindings: bindings, required: required}) do
      envs = System.get_env()

      bound_envs =
        bindings
        |> Map.new(fn {key, env} -> {key, Map.get(envs, env, :missing)} end)

      missing =
        bound_envs
        |> Enum.filter(fn {_, env} -> env == :missing end)
        |> Enum.map(fn {k, :missing} -> Keyword.get(bindings, k) end)

      if required && Enum.any?(missing) do
        {:error, "ENV vars not set: #{Enum.join(missing, ", ")}"}
      else
        envs =
          bound_envs
          |> Enum.reject(fn {_, env} -> env == :missing end)
          |> Enum.into(%{})
        {:ok, envs}
      end
    end
  end
end
