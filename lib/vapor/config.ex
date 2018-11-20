defmodule Vapor.Config do
  @moduledoc """
  This module provides conveniences for creating dynamic configuration layouts
  and overlays.
  """

  defmacro __using__(_opts) do
    quote do
      def set(key, value) when is_binary(key) do
        GenServer.call(__MODULE__, {:set, key, value})
      end

      def get(key, as: type) when is_binary(key) do
        case :ets.lookup(__MODULE__, key) do
          [] ->
            {:error, Vapor.NotFoundError}

          [{^key, value}] ->
            Vapor.Config.Converter.apply(value, type)
        end
      end

      def get!(key, as: type) when is_binary(key) do
        case get(key, as: type) do
          {:ok, val} ->
            val

          {:error, error} ->
            raise error, {key, type}
        end
      end
    end
  end

  defmodule Converter do
    @moduledoc """
               Applies conversions to values. This module is intended to be hidden from
               the end user.
               """ && false

    def apply(value, type) when is_atom(type) do
      case type do
        :string ->
          {:ok, value}

        :int ->
          to_int(value)

        :float ->
          to_float(value)

        :bool ->
          to_bool(value)
      end
    end

    def apply(value, type) when is_function(type, 1) do
      case type.(value) do
        {:ok, converted} ->
          {:ok, converted}

        {:error, _} ->
          {:error, Vapor.ConversionError}
      end
    end

    defp to_int(value) do
      case Integer.parse(value) do
        :error ->
          {:error, Vapor.ConversionError}

        {int, _} ->
          {:ok, int}
      end
    end

    defp to_float(value) do
      case Float.parse(value) do
        :error ->
          {:error, Vapor.ConversionError}

        {num, _} ->
          {:ok, num}
      end
    end

    defp to_bool("true"), do: {:ok, true}
    defp to_bool("false"), do: {:ok, false}
    defp to_bool(_), do: {:error, Vapor.ConversionError}
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
