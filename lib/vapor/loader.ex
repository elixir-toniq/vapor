defmodule Vapor.Loader do
  @moduledoc false
  # This module provides a unified way to load a series of providers and merge
  # them into a single result.
  alias Vapor.Provider

  def load(provider) when not is_list(provider) do
    load([provider])
  end
  def load(providers) do
    results =
      providers
      |> Enum.flat_map(&expand_modules/1)
      |> Enum.map(& Provider.load(&1))

    errors =
      results
      |> Enum.filter(& match?({:error, _}, &1))
      |> Enum.map(& normalize_error/1)

    if Enum.any?(errors) do
      {:error, errors}
    else
      config =
        results
        |> Enum.map(fn {:ok, v} -> v end)
        |> Enum.reduce(%{}, fn layer, config -> Map.merge(config, layer) end)
        |> Enum.into(%{})

      {:ok, config}
    end
  end

  defp normalize_error({:error, error}) do
    error
  end

  defp expand_modules(module) when is_atom(module) do
    Code.ensure_loaded(module)
    if function_exported?(module, :config_plan, 0) do
      List.wrap(module.config_plan())
    else
      raise ArgumentError, "#{module} does not export `config_plan/0`"
    end
  end

  defp expand_modules(foo), do: [foo]
end
