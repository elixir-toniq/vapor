defmodule Vapor.Converter do
  @moduledoc false
  # Applies conversions to values. This module is intended to be hidden from
  # the end user.

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

  defp to_int(value) when is_integer(value), do: {:ok, value}

  defp to_int(value) do
    case Integer.parse(value) do
      :error ->
        {:error, Vapor.ConversionError}

      {int, _} ->
        {:ok, int}
    end
  end

  defp to_float(value) when is_float(value), do: {:ok, value}

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
