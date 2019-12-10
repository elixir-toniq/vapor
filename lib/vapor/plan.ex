defmodule Vapor.Plan do
  @moduledoc false

  alias Vapor.Provider

  def new(providers) do
    providers
    |> Enum.map(fn provider -> if match?({_, _}, provider), do: provider, else: {provider, []} end)
    |> Enum.with_index()
    |> Enum.map(fn {provider, i} -> {i, provider} end)
    |> Enum.into(%{})
  end

  def watches(plan) do
    plan
    |> Enum.filter(fn {_i, {_p, opts}} -> Keyword.get(opts, :watch) end)
  end

  def load(plan) do
    results =
      plan
      |> Enum.map(fn {i, {provider, _ops}} -> {i, Provider.load(provider)} end)

    errors =
      results
      |> Enum.map(fn {_i, result} -> result end)
      |> Enum.filter(fn {result, _} -> result == :error end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      layers =
        results
        |> Enum.map(fn {i, {:ok, v}} -> {i, v} end)
        |> Enum.into(%{})

      {:ok, layers}
    end
  end
end
