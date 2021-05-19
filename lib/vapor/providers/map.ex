defmodule Vapor.Provider.Map do
  @moduledoc """
  The Map config module provides support for inputting configuration values
  from a map struct. This can be useful when integrating with other external 
  secret stores which provide secret payload as JSON. 
  Bindings must be specified at a keyword list.
  ## Example
      %Map{bindings: [foo: "FOO", bar: "VAR_BAR"]}
  """

  defstruct map: %{}, bindings: [], required: true

  defimpl Vapor.Provider do
    def load(%{map: map, bindings: bindings, required: required}) do
      bound_keys =
        bindings
        |> Enum.map(&normalize_binding/1)
        |> Enum.map(&create_binding(&1, map))
        |> Enum.into(%{})

      missing =
        bound_keys
        |> Enum.filter(fn {_, data} -> data.val == :missing end)
        |> Enum.map(fn {_k, data} -> data.key end)

      if required && Enum.any?(missing) do
        {:error, "Vars not set in map: #{Enum.join(missing, ", ")}"}
      else
        keys =
          bound_keys
          |> Enum.reject(fn {_, data} -> data.val == :missing end)
          |> Enum.map(fn {name, data} -> {name, data.val} end)
          |> Enum.into(%{})

        {:ok, keys}
      end
    end

    defp normalize_binding({name, variable}) do
      {name, %{val: nil, key: variable, opts: default_opts()}}
    end

    defp normalize_binding({name, variable, opts}) do
      {name, %{val: nil, key: variable, opts: Keyword.merge(default_opts(), opts)}}
    end

    defp create_binding({name, data}, keys) do
      case keys[data.key] do
        nil ->
          val =
            if data.opts[:default] != nil do
              data.opts[:default]
            else
              if data.opts[:required], do: :missing, else: nil
            end

          {name, %{data | val: val}}

        val ->
          # Call the map function which defaults to identity
          {name, %{data | val: data.opts[:map].(val)}}
      end
    end

    defp default_opts do
      [
        map: fn x -> x end,
        default: nil,
        required: true
      ]
    end
  end
end
