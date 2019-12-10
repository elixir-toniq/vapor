defmodule Vapor.Configuration do
  @moduledoc false
  # Manages a layered set of configuration values.
  # Not meant to be consumed by the end user
  import Norm

  defstruct [
    layers: %{overrides: %{}},
    translations: []
  ]

  def s do
    schema(%__MODULE__{
      layers: map_of(one_of([spec(is_atom()), spec(is_integer())]), spec(is_map())),
      translations: coll_of({spec(is_atom()), spec(is_function())}),
    })
  end

  @doc """
  Returns a new configuration with an initial set of layers and a list of
  initial actions to run.
  """
  def new(layers, translations) do
    # We're abusing term ordering here. The `:overrides` atom will always
    # be the highest precedence simply because its an atom
    configuration = conform!(%__MODULE__{
      layers: Map.merge(%{overrides: %{}}, layers),
      translations: translations,
    }, s())

    merged = materialize(configuration)

    actions =
      merged
      |> Enum.map(fn {key, value} -> {:upsert, key, value} end)

    {configuration, merged, actions}
  end

  @doc """
  Overwrites a value at a given path. Overwrites always take precedence over
  any other configuration values.
  """
  def set(config, key, value) do
    overrides = config.layers.overrides
    update(config, :overrides, Map.put(overrides, key, value))
  end

  @doc """
  Updates a specific layer in the configuration.
  """
  def update(%{layers: ls}=config, layer, value) do
    old_paths = materialize(config)
    new_config = %{config | layers: Map.put(ls, layer, value)}
    new_paths = materialize(new_config)
    actions = diff(new_paths, old_paths)

    {new_config, new_paths, actions}
  end

  defp materialize(config) do
    config
    |> flatten()
    |> Enum.map(& do_translation(&1, config.translations))
    |> Enum.into(%{})
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
    |> Enum.map(fn {_, map} -> map end)
    |> Enum.reduce(%{}, fn map, acc -> Map.merge(acc, map) end)
  end

  defp do_translation({key, value}, translations) do
    case Enum.find(translations, fn {k, _f} -> key == k end) do
      {_, f} -> {key, f.(value)}
      _ -> {key, value}
    end
  end
end
