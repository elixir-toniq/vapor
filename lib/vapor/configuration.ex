defmodule Vapor.Configuration do
  defstruct layers: %{}, versions: []

  def keys(%{layers: layers}) do
    layers
    |> Enum.sort(fn {a, _}, {b, _} -> a < b end) # Ensure proper sorting
    |> Enum.map(fn {_, map} -> pathify_keys(map) end)
    |> Enum.reduce(%{}, fn keys, acc -> Map.merge(acc, keys) end)
  end

  def load(plan) when is_map(plan) do
    results =
      plan
      |> Enum.map(fn {key, provider} -> {key, Vapor.Provider.load(provider)} end)

    errors =
      results
      |> Enum.filter(fn {_, {result, _}} -> result == :error end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      layers =
        results
        |> Enum.map(fn {key, {:ok, v}} -> {key, v} end)
        |> Enum.into(%{})

      {:ok, %__MODULE__{layers: layers}}
    end
  end

  defp pathify_keys(map) when is_map(map) do
    map
    |> pathify_keys([], [])
    |> Enum.into(%{})
  end

  defp pathify_keys(map, path_so_far, completed_keys) do
    Enum.reduce(map, completed_keys, fn
      {k, v}, acc when is_map(v) ->
        pathify_keys(v, [k | path_so_far], acc)

      {k, v}, acc when is_list(k) ->
        [{k, v} | acc]

      {k, v}, acc ->
        [{Enum.reverse([k | path_so_far]), v} | acc]
    end)
  end
end
