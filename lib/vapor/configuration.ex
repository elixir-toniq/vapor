defmodule Vapor.Configuration do
  defstruct layers: %{overrides: %{}}, versions: []

  def new(layers) do
    # We're abusing term ordering here. The `:overrides` atom will always
    # be the highest precedence simply because its an atom
    configuration = %__MODULE__{layers: Map.merge(%{overrides: %{}}, layers)}

    actions =
      configuration.layers
      |> Enum.sort(fn {a, _}, {b, _} -> a < b end) # Ensure proper sorting
      |> Enum.map(fn {_, map} -> pathify_keys(map) end)
      |> Enum.reduce(%{}, fn paths, acc -> Map.merge(acc, paths) end)
      |> Enum.map(fn {path, value} -> {:upsert, path, value} end)

    {configuration, actions}
  end

  def set(config, path, value) do
    overrides = config.layers.overrides
    update(config, :overrides, Map.put(overrides, path, value))
  end

  def update(%{layers: ls}=config, layer, value) do
    old_paths = keys(config)
    new_config = %{config | layers: Map.put(ls, layer, value)}
    new_paths = keys(new_config)
    actions = diff(new_paths, old_paths)

    {new_config, actions}
  end

  def diff(new_paths, old_paths) when is_map(new_paths) and is_map(old_paths) do
    new_list =
      new_paths
      |> Enum.to_list

    old_list =
      old_paths
      |> Enum.to_list

    # This is expensive but it allows us to only diff the meaningful bits
    diff(new_list -- old_list, old_list -- new_list, [])
  end
  def diff([], old_paths, acc) do
    acc ++ Enum.map(old_paths, fn {path, _} -> {:delete, path} end)
  end
  def diff(new_paths, [], acc) do
    acc ++ Enum.map(new_paths, fn {path, value} -> {:upsert, path, value} end)
  end
  def diff([{path, value} | nps], old_paths, acc) do
    acc = [{:upsert, path, value} | acc]

    case Enum.find_index(old_paths, fn {old_path, _} -> path == old_path end) do
     nil ->
        diff(nps, old_paths, acc)

      # If we find an index then we need to remove it from the old list
      index ->
        diff(nps, List.delete_at(old_paths, index), acc)
    end
  end

  defp keys(%{layers: layers}) do
    layers
    |> Enum.sort(fn {a, _}, {b, _} -> a < b end) # Ensure proper sorting
    |> Enum.map(fn {_, map} -> pathify_keys(map) end)
    |> Enum.reduce(%{}, fn keys, acc -> Map.merge(acc, keys) end)
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
