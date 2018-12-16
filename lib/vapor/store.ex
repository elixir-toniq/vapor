defmodule Vapor.Store do
  @moduledoc """
  Module that loads config
  Attempts to load the config 10 times before returning :error
  """

  use GenServer

  alias Vapor.Configuration

  def start_link({module, plan}) do
    GenServer.start_link(__MODULE__, {module, plan}, name: module)
  end

  def init({module, plan}) do
    table_opts = [
      :set,
      :protected,
      :named_table,
      read_concurrency: true,
    ]

    ^module = :ets.new(module, table_opts)

    case Configuration.load(plan) do
      {:ok, config} ->
        config
        |> Configuration.keys
        |> Enum.each(fn key -> :ets.insert(module, key) end)

        {:ok, %{config: config, table: module}}

      {:error, _} ->
        {:stop, :could_not_load_config}
    end
  end

  def handle_call({:set, key, value}, _from, %{table: tab} = state) do
    :ets.insert(tab, {key, value})

    {:reply, {:ok, value}, state}
  end
end
