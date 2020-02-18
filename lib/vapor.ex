defmodule Vapor do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Loads a configuration plan.
  """
  def load(providers, translations \\ [])
  def load(providers, translations) do
    with {:ok, map} <- Vapor.Loader.load(providers) do
      transformed =
        map
        |> Enum.map(&apply_translation(&1, translations))
        |> Enum.into(%{})

      {:ok, transformed}
    end
  end

  @doc """
  Loads a configuration plan or raises
  """
  def load!(providers, translations \\ [])
  def load!(providers, translations) do
    case load(providers, translations) do
      {:ok, config} ->
        config

      {:error, error} ->
        raise error
    end
  end

  defp apply_translation({key, value}, translations) do
    case Enum.find(translations, fn {k, _f} -> key == k end) do
      {_, f} -> {key, f.(value)}
      _ -> {key, value}
    end
  end
end

