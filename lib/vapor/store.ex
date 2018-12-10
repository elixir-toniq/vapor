defmodule Vapor.Store do
  use GenServer

  @moduledoc """
    Module that loads config
    Attempts to load the config 10 times before returning :error
  """

  def start_link({module, plans}) do
    GenServer.start_link(__MODULE__, {module, plans}, name: module)
  end

  def init({module, plans}) do
    ^module = :ets.new(module, [:set, :protected, :named_table])

    case load_config(module, plans) do
      :ok ->
        {:ok, %{plans: plans, table: module}}

      :error ->
        {:stop, :could_not_load_config}
    end
  end

  def handle_call({:set, key, value}, _from, %{table: tab} = state) do
    :ets.insert(tab, {key, value})

    {:reply, {:ok, value}, state}
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

  defp load_config(table, plans, retry_count \\ 0)
  defp load_config(_table, [], _), do: :ok
  defp load_config(_table, _, 10), do: :error

  defp load_config(table, [plan | rest], retry_count) do
    case Vapor.Provider.load(plan) do
      {:ok, configs} ->
        configs
        |> pathify_keys
        |> Enum.each(fn k_v ->
          :ets.insert(table, k_v)
        end)

        load_config(table, rest, 0)

      {:error, _e} ->
        load_config(table, [plan | rest], retry_count + 1)
    end
  end
end
