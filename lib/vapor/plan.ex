defmodule Vapor.Plan do
  def new do
    %{}
  end

  def merge(plan, provider) do
    plan
    |> Map.put(next_key(plan), provider)
  end

  defp next_key(plan) do
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

