defmodule Vapor.Loader do
  @moduledoc false
  # This module provides a unified way to load a series of providers and merge
  # them into a single result.
  alias Vapor.Provider
  alias Vapor.LoadError

  def load(provider) when not is_list(provider) do
    load([provider])
  end
  def load(providers) do
    results =
      providers
      |> Enum.map(& Provider.load(&1))

    errors =
      results
      |> Enum.filter(& match?({:error, _}, &1))
      |> Enum.map(fn {:error, error} -> error end)

    if Enum.any?(errors) do
      error = LoadError.exception(errors)
      {:error, error}
    else
      config =
        results
        |> Enum.map(fn {:ok, v} -> v end)
        |> Enum.reduce(%{}, fn layer, config -> Map.merge(config, layer) end)
        |> Enum.into(%{})

      {:ok, config}
    end
  end
end
