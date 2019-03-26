defmodule Vapor.Configuration do
  @moduledoc false
  # Manages a layered set of configuration values.
  # Not meant to be consumed by the end user

  defstruct layers: %{overrides: %{}}, versions: []

  @typedoc """
  The path to store the value at. Serves as a key.
  """
  @type path :: list(String.t)

  @typedoc """
  The action needed to achieve consistency with the desired configuration.
  """
  @opaque action :: {:upsert, path, term()}
                | {:delete, path}

  @typedoc """
  The "layer" for the configuration. Its either an integer or overrides.
  Higher integers overwrite lower integers
  """
  @opaque layer :: integer()
               | :overrides

  @opaque t :: %__MODULE__{
    layers: %{required(layer) => map()},
    versions: [],
  }

  @doc """
  Returns a new configuration with an initial set of layers and a list of
  initial actions to run.
  """
  @spec new(%{}) :: {t(), list(action())}
  def new(layers) do
    # We're abusing term ordering here. The `:overrides` atom will always
    # be the highest precedence simply because its an atom
    configuration = %__MODULE__{layers: Map.merge(%{overrides: %{}}, layers)}

    actions =
      configuration
      |> flatten
      |> Enum.map(fn {path, value} -> {:upsert, path, value} end)

    {configuration, actions}
  end

  @doc """
  Overwrites a value at a given path. Overwrites always take precedence over
  any other configuration values.
  """
  @spec set(t(), path(), term()) :: {t(), list(action)}
  def set(config, path, value) do
    overrides = config.layers.overrides
    update(config, :overrides, Map.put(overrides, path, value))
  end

  @doc """
  Updates a specific layer in the configuration.
  """
  @spec update(t(), layer(), map()) :: {t(), list(action)}
  def update(%{layers: ls}=config, layer, value) do
    old_paths = flatten(config)
    new_config = %{config | layers: Map.put(ls, layer, value)}
    new_paths = flatten(new_config)
    actions = diff(new_paths, old_paths)

    {new_config, actions}
  end

  # Takes an old configuration and new configuration and returns a list of
  # commands needed to convert the old config into the new config.
  defp diff(new_paths, old_paths) when is_map(new_paths) and is_map(old_paths) do
    new_list =
      new_paths
      |> Enum.to_list

    old_list =
      old_paths
      |> Enum.to_list

    # This is expensive but it allows us to only diff the meaningful bits
    diff(new_list -- old_list, old_list -- new_list, [])
  end

  # If we're out of new paths then any remaining old paths are deletes.
  defp diff([], old_paths, acc) do
    acc ++ Enum.map(old_paths, fn {path, _} -> {:delete, path} end)
  end

  # If we're out of old paths then everything left is an upsert by default
  defp diff(new_paths, [], acc) do
    acc ++ Enum.map(new_paths, fn {path, value} -> {:upsert, path, value} end)
  end

  # If we get here then we know that we need to do an upsert and remove any
  # old configs with a matching path to our new config. Then we can keep
  # recursing
  defp diff([{path, value} | nps], old_paths, acc) do
    acc = [{:upsert, path, value} | acc]
    old_paths = Enum.reject(old_paths, fn {old_path, _} -> path == old_path end)
    diff(nps, old_paths, acc)
  end

  defp flatten(%{layers: layers}) do
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
