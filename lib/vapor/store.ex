defmodule Vapor.Store do
  use GenServer

  def start_link({module, plans}) do
    GenServer.start_link(__MODULE__, {module, plans}, name: module)
  end

  def init({module, plans}) do
    ^module = :ets.new(module, [:set, :protected, :named_table])

    case load_config(module, %{}, plans) do
      {:ok, config} ->
        case module.init(config) do
          {:ok, config} ->
            store_config(module, config)
            {:ok, %{plans: plans, table: module}}

          result ->
            result
        end
      :error ->
        {:stop, :could_not_load_config}
    end
  end

  def handle_call({:set, key, value}, _from, %{table: tab} = state) do
    :ets.insert(tab, {key, value})

    {:reply, {:ok, value}, state}
  end

  defp store_config(table, configs) do
    Enum.each(configs, fn k_v ->
      :ets.insert(table, k_v)
    end)
  end

  defp load_config(table, configs, plans, retry_count \\ 0)

  defp load_config(_table, configs, [], _), do: {:ok, configs}

  defp load_config(_table, _, _, 10), do: :error

  defp load_config(table, configs, [plan | rest], retry_count) do
    case Vapor.Provider.load(plan) do
      {:ok, new_configs} ->
        load_config(table, Map.merge(configs, new_configs), rest, 0)

      {:error, _e} ->
        load_config(table, configs, [plan | rest], retry_count + 1)
    end
  end
end
