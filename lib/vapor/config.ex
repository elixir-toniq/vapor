defmodule Vapor.Config do
  @moduledoc """
  This module provides conveniences for creating dynamic configuration layouts
  and overlays.
  """

  @default_watch_opts [
    refresh_interval: 30_000,
  ]

  @doc """
  Creates an initial configuration.
  """
  def default do
    %{}
  end

  @doc """
  Merges an existing configuration plan with a new configuration plan.
  Plans are stacked and applied in the order that they are merged.
  """
  def merge(plan, provider) do
    plan
    |> Map.put(next_layer(plan), %{watch: false, provider: provider})
  end

  @doc """
  Adds a provider to the configuration plan. This provider will initially be
  loaded in the order that its specified. After the initial load the provider
  be watched for updates.
  """
  def watch(plan, provider, opts \\ []) do
    watch_opts =
      @default_watch_opts
      |> Keyword.merge(opts)

    plan
    |> Map.put(next_layer(plan), %{watch: true, provider: provider, opts: watch_opts})
  end

  @doc """
  Returns a list of providers that are being watched.
  """
  def watches(plan) do
    plan
    |> Enum.filter(fn {_, p} -> p.watch end)
  end

  defp next_layer(plan) do
    if Enum.empty?(Map.keys(plan)) do
      0
    else
      plan
      |> Map.keys
      |> Enum.max()
      |> Kernel.+(1)
    end
  end
end
