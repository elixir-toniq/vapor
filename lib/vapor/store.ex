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
    Plan,
    Watch,
  }

  def start_link({module, config}) do
    GenServer.start_link(__MODULE__, {module, config}, name: module)
  end

  def update(store, layer, new_config) do
    GenServer.call(store, {:update, layer, new_config})
  end

  def init({module, config}) do
    plan = Plan.new(config.plan)

    case Plan.load(plan) do
      {:ok, layers} ->
        {config, merged, actions} = Configuration.new(layers, config[:translations] || [])

        with :ok <- module.init(merged) do
          process_actions(actions, module)

          for watch <- Plan.watches(plan) do
            start_watch(watch, module)
          end

          {:ok, %{config: config, table: module}}
        end

      {:error, error} ->
        {:stop, {:could_not_load_config, error}}
    end
  end

  def handle_call({:update, layer, new_values}, _, %{config: config}=state) do
    {new_config, merged, actions} = Configuration.update(config, layer, new_values)
    process_actions(actions, state.table)
    state.table.handle_change(merged)

    {:reply, :ok, %{state | config: new_config}}
  end

  def handle_call({:set, key, value}, _from, %{config: config}=state) do
    {new_config, merged, actions} = Configuration.set(config, key, value)
    process_actions(actions, state.table)
    state.table.handle_change(merged)

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

  defp start_watch({layer, provider}, module) do
    Watch.Supervisor.start_child(module, %{layer: layer, provider: provider, store: module})
  end
end
