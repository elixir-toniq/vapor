defmodule Vapor.Config do
  @moduledoc """
  This module provides conveniences for creating dynamic configuration layouts
  and overlays.
  """

  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor,
          restart: :permanent,
          shutdown: 500
        }
      end

      def set(key, value) when is_binary(key) do
        GenServer.call(__MODULE__, {:set, key, value})
      end

      def get(key, as: type) when is_binary(key) and is_atom(type) do
        get!(key, as: type)
      rescue
        Vapor.NotFoundError ->
          nil
      end

      def get!(key, as: type) when is_binary(key) and is_atom(type) do
        case :ets.lookup(__MODULE__, key) do
          [] ->
            raise Vapor.NotFoundError, key

          [{^key, value}] ->
            value
        end
      end
    end
  end

  @doc """
  Creates an initial configuration.
  """
  def default do
    []
  end

  @doc """
  Merges an existing configuration plan with a new configuration plan.
  Plans are stacked and applied in the order that they are merged.
  """
  def merge(existing_plan, plan) do
    existing_plan ++ [plan]
  end
end
