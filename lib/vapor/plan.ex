defmodule Vapor.Plan do

  @default_watch_opts [
    refresh_interval: 30_000
  ]

  def new do
    %{}
  end

  def merge(plan, provider) do
    plan
    |> Map.put(next_layer(plan), %{watch: false, provider: provider})
  end

  def watch(plan, provider, opts \\ []) do
    watch_opts =
      @default_watch_opts
      |> Keyword.merge(opts)

    plan
    |> Map.put(next_layer(plan), %{watch: true, provider: provider, opts: watch_opts})
  end

  def load(plans) when is_map(plans) do
    results =
      plans
      |> Enum.map(fn {key, plan} -> {key, Vapor.Provider.load(plan.provider)} end)

    errors =
      results
      |> Enum.filter(fn {_, {result, _}} -> result == :error end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      layers =
        results
        |> Enum.map(fn {key, {:ok, v}} -> {key, v} end)
        |> Enum.into(%{})

      {:ok, layers}
    end
  end

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

