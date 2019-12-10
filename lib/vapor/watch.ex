defmodule Vapor.Watch do
  @moduledoc false

  use GenServer

  alias Vapor.{
    Provider
  }

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    state = Map.merge(%{error_count: 0, current_alarm: false}, state)
    schedule_refresh(state.provider)
    {:ok, state}
  end

  def handle_info(:refresh, %{provider: {provider, opts}, store: store, layer: layer}=state) do
    case Provider.load(provider) do
      {:ok, new_config} ->
        # We don't mind if we repeatedly spam the logs when there's a problem,
        # but if everything is okay, we ought not attempt to clear an alarm
        # that might not exist because the attempt with spam the logs.
        if state.current_alarm do
          :alarm_handler.clear_alarm({:vapor, {layer, provider}})
        end
        :ok = Vapor.Store.update(store, layer, new_config)
        schedule_refresh({provider, opts})
        {:noreply, %{state | current_alarm: false}}

      {:error, _reason} ->
        # We're intentionally NOT passing through the lower-level `reason` to
        # the alarm_handler, since that information gets logged. The underlying
        # configuration source could have sensitive information, like passwords,
        # and we don't want those to end up in logs just because there was a
        # temporary problem. By alarming with the layer and provider, we ought
        # to give troubleshooters a head start in knowing where to investigate.
        :alarm_handler.set_alarm({{:vapor, {layer, provider}}, :redacted})
        schedule_refresh({provider, opts})
        {:noreply, %{state | current_alarm: true, error_count: state.error_count + 1}}
    end
  end

  defp schedule_refresh({_provider, opts}) do
    Process.send_after(self(), :refresh, opts[:refresh_interval] || 3_000)
  end
end

