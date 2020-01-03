defmodule Vapor do
  @moduledoc """
  Vapor provides mechanisms for loading runtime configuration in your system.
  """

  alias Vapor.Provider
  alias Vapor.LoadError

  @doc """
  Loads a configuration plan.
  """
  def load(providers, translations \\ [])
  def load(providers, translations) do
    results =
      providers
      |> Enum.map(& Provider.load(&1))

    errors =
      results
      |> Enum.filter(& match?({:error, _}, &1))
      |> Enum.map(fn {:error, error} -> error end)

    if Enum.any?(errors) do
      error = LoadError.exception(errors)
      {:error, error}
    else
      config =
        results
        |> Enum.map(fn {:ok, v} -> v end)
        |> Enum.reduce(%{}, fn layer, config -> Map.merge(config, layer) end)
        |> Enum.map(&apply_translation(&1, translations))
        |> Enum.into(%{})

      {:ok, config}
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

