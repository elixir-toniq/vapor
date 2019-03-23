defmodule Vapor.Provider.Env do
  @moduledoc """
  The Env config module provides support for pulling configuration values
  from the environment. It can do this by either specifying a prefix or by
  specifying specific bindings from keys to environment variables.

  ## Loading configuration by prefix

  If a prefix is used then the variable will be normalized by removing the
  prefix, downcasing the text, and converting all underscores into nested keys

  ## Loading with bindings

  Specific bindings be also be specified. They are case sensitive
  """

  defstruct prefix: :none, bindings: []

  @type bindings :: Keyword.t(String.t())

  @type t :: %__MODULE__{
          prefix: :none | String.t(),
          bindings: bindings
        }

  @spec with_prefix(String.t()) :: t
  def with_prefix(prefix) when is_binary(prefix) do
    %__MODULE__{prefix: build_prefix(prefix)}
  end

  @doc """
  Creates a configuration plan with explicit bindings.

  Env.with_bindings([foo: "FOO", bar: "BAR"])
  """
  @spec with_bindings(bindings()) :: t
  def with_bindings(opts) when is_list(opts) do
    %__MODULE__{
      prefix: :none,
      bindings: opts
    }
  end

  defp build_prefix(prefix), do: "#{prefix}_"

  defimpl Vapor.Provider do
    def load(%{prefix: :none, bindings: bindings}) do
      envs = System.get_env()

      bound_envs =
        bindings
        |> Enum.into(%{}, fn {key, env} -> {Atom.to_string(key), Map.get(envs, env, :missing)} end)

      missing =
        bound_envs
        |> Enum.filter(fn {_, v} -> v == :missing end)

      if Enum.any?(missing) do
        {:error, missing}
      else
        {:ok, bound_envs}
      end
    end

    def load(%{prefix: prefix}) do
      env = System.get_env()

      prefixed_envs =
        env
        |> Enum.filter(&matches_prefix?(&1, prefix))
        |> Enum.into(%{}, fn {k, v} -> {normalize(k, prefix), v} end)

      {:ok, prefixed_envs}
    end

    defp normalize(str, prefix) do
      str
      |> String.replace_leading(prefix, "")
      |> String.downcase()
      |> String.split("_")
    end

    defp matches_prefix?({k, _v}, prefix) do
      String.starts_with?(k, prefix)
    end
  end
end
