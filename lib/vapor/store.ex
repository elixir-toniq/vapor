defmodule Vapor.Store do
  @moduledoc false
  # This module maintains the storage for configuration values.
  # When the store process is initialized it will block and
  # attempt to load the config 10 times before returning :error which will
  # cause the boot process to halt. Once the boot process has completed any
  # updates will be handled gracefully but cause alarms to be triggered.

  use GenServer

  alias Vapor.{
    Configuration,
    Provider,
    Watch,
  }

  def start_link({module, config}) do
    GenServer.start_link(__MODULE__, {module, config}, name: module)
  end

  def update(store, layer, new_config) do
    GenServer.call(store, {:update, layer, new_config})
  end

  def init({module, config}) do
    table_opts = [
      :set,
      :protected,
      :named_table,
      read_concurrency: true,
    ]

    ^module = :ets.new(module, table_opts)

    case load(config.plan) do
      {:ok, layers} ->
        translations = config[:translations] || []

        merged =
          layers
          |> Enum.reduce(%{}, fn l, acc -> Map.merge(acc, Enum.into(l, %{})) end)
          |> Enum.map(& do_translation(&1, translations))
          |> Enum.into(%{})

        with {:ok, values} <- module.init(merged) do
          for {key, value} <- values do
            :ets.insert(module, {key, value})
          end

          {:ok, %{config: config, table: module}}
        end

      {:error, error} ->
        {:stop, {:could_not_load_config, error}}
    end
  end

  def handle_call({:update, layer, new_values}, _, %{config: config}=state) do
    {new_config, actions} = Configuration.update(config, layer, new_values)
    process_actions(actions, state.table)

    {:reply, :ok, %{state | config: new_config}}
  end

  def handle_call({:set, key, value}, _from, %{config: config}=state) do
    # {new_config, actions} = Configuration.set(config, key, value)
    # process_actions(actions, state.table)

    {:reply, {:ok, value}, %{state | config: new_config}}
  end

  defp process_actions(actions, table) do
    Enum.each(actions, fn action ->
      case action do
        {:upsert, key, value} ->
          :ets.insert(table, {key, value})

        {:delete, key} ->
          :ets.delete(table, key)
      end
    end)
  end

  defp load(providers) do
    results =
      providers
      |> Enum.map(fn provider -> Provider.load(provider) end)

    errors =
      results
      |> Enum.filter(fn {result, _} -> result == :error end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      layers = Enum.into(results, [], fn {:ok, v} -> v end)

      {:ok, layers}
    end
  end

  defp do_translation({key, value}, translations) do
    case Enum.find(translations, fn {k, _f} -> key == k end) do
      {_, f} -> {key, f.(value)}
      _ -> {key, value}
    end
  end

  defp start_watch(layer, plan, module) do
    Watch.Supervisor.start_child(module, %{layer: layer, plan: plan, store: module})
  end
end
