defmodule Vapor.Provider.Env do
  @moduledoc """
  The Env config module provides support for pulling configuration values
  from the environment. Bindings must be specified at a keyword list.

  ## Example

      %Env{bindings: [foo: "FOO", bar: "VAR_BAR"]}
  """

  defstruct bindings: [], required: true

  defimpl Vapor.Provider do
    def load(%{bindings: bindings, required: required}) do
      envs = System.get_env()

      bound_envs =
        bindings
        |> Enum.map(&normalize_binding/1)
        |> Enum.map(&create_binding(&1, envs))
        |> Enum.into(%{})

      missing =
        bound_envs
        |> Enum.filter(fn {_, data} -> data.val == :missing end)
        |> Enum.map(fn {_k, data} -> data.env end)

      if required && Enum.any?(missing) do
        {:error, "ENV vars not set: #{Enum.join(missing, ", ")}"}
      else
        envs =
          bound_envs
          |> Enum.reject(fn {_, data} -> data.val == :missing end)
          |> Enum.map(fn {name, data} -> {name, data.val} end)
          |> Enum.into(%{})

        {:ok, envs}
      end
    end

    defp normalize_binding({name, variable}) do
      {name, %{val: nil, env: variable, opts: default_opts()}}
    end
    defp normalize_binding({name, variable, opts}) do
      {name, %{val: nil, env: variable, opts: Keyword.merge(default_opts(), opts)}}
    end

    defp create_binding({name, data}, envs) do
      case envs[data.env] do
        nil ->
          val = if data.opts[:default] != nil do
            data.opts[:default]
          else
            if data.opts[:required], do: :missing, else: nil
          end
          {name, %{data | val: val}}

        env ->
          # Call the map function which defaults to identity
          {name, %{data | val: data.opts[:map].(env)}}
      end
    end

    defp default_opts do
      [
        map: fn x -> x end,
        default: nil,
        required: true,
      ]
    end
  end
end
