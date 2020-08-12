defmodule Vapor do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Loads a configuration plan.
  """
  def load(providers) do
    with {:error, errors} <- Vapor.Loader.load(providers) do
      {:error, Vapor.LoadError.exception(errors)}
    end
  end

  def load(providers, translations) do
    IO.warn("load/2 and load!/2 are deprecated. Please add translations to each binding")

    case Vapor.Loader.load(providers) do
      {:ok, map} ->
        transformed =
          map
          |> Enum.map(&apply_translation(&1, translations))
          |> Enum.into(%{})

        {:ok, transformed}

      {:error, errors} ->
        {:error, Vapor.LoadError.exception(errors)}
    end
  end

  @doc """
  Loads a configuration plan or raises
  """
  def load!(providers) do
    case load(providers) do
      {:ok, config} ->
        config

      {:error, error} ->
        raise error
    end
  end

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

