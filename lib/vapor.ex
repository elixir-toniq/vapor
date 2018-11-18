defmodule Vapor do
  @moduledoc """
  Vapor provides mechanisms for handling runtime configuration in your system.
  """

  @doc """
  Starts a configuration store and any watches.
  """
  def start_link(module, plans, opts) do
    if opts[:name] do
      Vapor.Store.Supervisor.start_link(module, plans, opts)
    else
      raise Vapor.ConfigurationError, "must supply a `:name` argument"
    end
  end
end

