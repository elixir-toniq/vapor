defmodule Vapor.Provider.File do
  @moduledoc """
  Module for loading supported file format configs
  Supported file formats: .json, .toml, .yaml
  """
  import Norm

  defstruct path: nil, bindings: []

  def s do
    bindings = coll_of({
      spec(is_atom()),
      one_of([
        spec(is_binary()),
        coll_of(spec(is_binary())),
      ])
    })

    schema(%__MODULE__{
      path: spec(is_binary()),
      bindings: bindings,
    })
  end

  defimpl Vapor.Provider do
    def load(provider) do
      provider = conform!(provider, Vapor.Provider.File.s())
      format = format(provider.path)

      str = read!(provider.path)

      with {:ok, data} <- decode(str, format) do
        bound =
          provider.bindings
          |> Enum.map(fn {key, path} -> {key, get(data, path) || :missing} end)
          |> Enum.into(%{})

        missing =
          bound
          |> Enum.filter(fn {_, val} -> val == :missing end)
          |> Enum.map(fn {k, :missing} -> Keyword.get(provider.bindings, k) end)

        if Enum.any?(missing) do
          {:error, "Missing keys in file: #{Enum.join(missing, ", ")}"}
        else
          {:ok, bound}
        end
      end
    end

    def get(data, path) do
      get_in(data, List.wrap(path))
    end

    def decode(str, format) do
      case format do
        :json ->
          Jason.decode(str)

        :toml ->
          Toml.decode(str)

        :yaml ->
          YamlElixir.read_from_string(str)
      end
    end

    def read!(path) do
      case File.read(path) do
        {:ok, str} ->
          str

        {:error, _} ->
          raise Vapor.FileNotFoundError, path
      end
    end

    def format(path) do
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
