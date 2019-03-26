defmodule Vapor.Store do
  @moduledoc false
  # This module maintains the storage for configuration values.
  # When the store process is initialized it will block and
  # attempt to load the config 10 times before returning :error which will
  # cause the boot process to halt. Once the boot process has completed any
  # updates will be handled gracefully but cause alarms to be triggered.

  use GenServer

  alias Vapor.{
    Config,
    Configuration,
    Provider,
    Watch,
  }

  def start_link({module, plans}) do
    GenServer.start_link(__MODULE__, {module, plans}, name: module)
  end

  def update(store, layer, new_config) do
    GenServer.call(store, {:update, layer, new_config})
  end

  def init({module, plans}) do
    table_opts = [
      :set,
      :protected,
      :named_table,
      read_concurrency: true,
    ]

    ^module = :ets.new(module, table_opts)

    case load(plans) do
      {:ok, layers} ->
        {config, actions} = Configuration.new(layers)
        process_actions(actions, module)

        plans
        |> Config.watches
        |> Enum.each(fn {layer, plan} -> start_watch(layer, plan, module) end)

        {:ok, %{config: config, table: module}}

      {:error, _} ->
        {:stop, :could_not_load_config}
    end
  end

  def handle_call({:update, layer, new_values}, _, %{config: config}=state) do
    {new_config, actions} = Configuration.update(config, layer, new_values)
    process_actions(actions, state.table)

    {:reply, :ok, %{state | config: new_config}}
  end

  def handle_call({:set, key, value}, _from, %{config: config}=state) do
    {new_config, actions} = Configuration.set(config, key, value)
    process_actions(actions, state.table)

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

  defp load(plans) when is_map(plans) do
    results =
      plans
      |> Enum.map(fn {key, plan} -> {key, Provider.load(plan.provider)} end)

    errors =
      results
      |> Enum.filter(fn {_, {result, _}} -> result == :error end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      layers =
        results
        |> Enum.into(%{}, fn {key, {:ok, v}} -> {key, v} end)

      {:ok, layers}
    end
  end

  defp start_watch(layer, plan, module) do
    Watch.Supervisor.start_child(module, %{layer: layer, plan: plan, store: module})
  end
end
