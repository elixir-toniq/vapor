defmodule Vapor.Provider.File do
  @moduledoc """
  Module for loading supported file format configs
  Supported file formats: .json, .toml, .yaml. Bindings to specific keys must
  be provided as a keyword list. The values for each key must be either a string
  or a path based on the Access protocol.

  ## Example

      %File{path: "config.toml", bindings: [foo: "foo", nested: ["some", "nested", "value"]]}
  """
  import Norm

  defstruct path: nil, bindings: [], required: true

  def s do
    binding = one_of([
      {spec(is_atom()), one_of([spec(is_binary()), spec(is_list())])},
      {spec(is_atom()), one_of([spec(is_binary()), spec(is_list())]), spec(is_list())},
    ])

    schema(%__MODULE__{
      path: spec(is_binary()),
      bindings: coll_of(binding),
      required: spec(is_boolean)
    })
  end

  defimpl Vapor.Provider do
    def load(provider) do
      provider = conform!(provider, Vapor.Provider.File.s())
      format = format(provider.path)

      str = read!(provider.path)

      with {:ok, file} <- decode(str, format) do
        bound =
          provider.bindings
          |> Enum.map(&normalize_binding/1)
          |> Enum.map(&create_binding(&1, file))
          |> Enum.into(%{})

        missing =
          bound
          |> Enum.filter(fn {_, data} -> data.val == :missing end)
          |> Enum.map(fn {_, data} -> data.env end)

        if provider.required && Enum.any?(missing) do
          {:error, "Missing keys in file: #{Enum.join(missing, ", ")}"}
        else
          envs =
            bound
            |> Enum.reject(fn {_, data} -> data.val == :missing end)
            |> Enum.map(fn {name, data} -> {name, data.val} end)
            |> Enum.into(%{})

          {:ok, envs}
        end
      end
    end

    defp normalize_binding({name, variable}) do
      {name, %{val: nil, env: variable, opts: default_opts()}}
    end
    defp normalize_binding({name, variable, opts}) do
      {name, %{val: nil, env: variable, opts: Keyword.merge(default_opts(), opts)}}
    end

    defp create_binding({name, data}, envs) do
      case get(envs, data.env) do
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

    defp get(data, path) do
      get_in(data, List.wrap(path))
    end

    defp decode(str, format) do
      case format do
        :json ->
          Jason.decode(str)

        :toml ->
          Toml.decode(str)

        :yaml ->
          YamlElixir.read_from_string(str)
      end
    end

    defp read!(path) do
      case File.read(path) do
        {:ok, str} ->
          str

        {:error, _} ->
          raise Vapor.FileNotFoundError, path
      end
    end

    defp format(path) do
      case Path.extname(path) do
        ".json" ->
          :json

        ".toml" ->
          :toml

        ".yaml" ->
          :yaml

        _ ->
          raise Vapor.FileFormatNotFoundError, path

      end
    end
  end
end
