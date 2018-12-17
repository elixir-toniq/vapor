defmodule Vapor.Store.Supervisor do
  @moduledoc """
             This provides the supervisor for the store and any processes used to trigger
             live updates.
             """ && false

  use Supervisor

  alias Vapor.{
    Store,
    Watch
  }

  def start_link(module, plans, opts) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, {module, plans}, name: :"#{name}_sup")
  end

  def stop(name) do
    Supervisor.stop(:"#{name}_sup")
  end

  def init({module, plans}) do
    children = [
      {Vapor.Watch.Supervisor, [name: Watch.Supervisor.sup_name(module)]},
      {Vapor.Store, {module, plans}},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
