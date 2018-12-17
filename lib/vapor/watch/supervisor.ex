defmodule Vapor.Watch.Supervisor do
  use DynamicSupervisor

  def start_link(name: name) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: name)
  end

  def sup_name(module) do
    :"#{module}_watch_sup"
  end

  def start_child(module, state) do
    spec = {Vapor.Watch, state}
    DynamicSupervisor.start_child(sup_name(module), spec)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
