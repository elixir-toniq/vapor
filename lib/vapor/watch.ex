defmodule Vapor.Watch do
  use GenServer

  alias Vapor.{
    Provider
  }

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    schedule_refresh(state.plan)
    {:ok, state}
  end

  def handle_info(:refresh, %{plan: plan, store: store, layer: layer}=state) do
    case Provider.load(plan.provider) do
      {:ok, new_config} ->
        :ok = Vapor.Store.update(store, layer, new_config)
        schedule_refresh(plan)
        {:noreply, state}

      {:error, _} ->
        schedule_refresh(plan)
        {:noreply, %{state | error_count: state.error_count + 1}}
    end
  end

  defp schedule_refresh(%{opts: [refresh_interval: interval]}) do
    Process.send_after(self(), :refresh, interval)
  end
end
