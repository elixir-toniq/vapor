defmodule Vapor do
  @moduledoc """
  Vapor provides mechanisms for handling runtime configuration in your system.
  """

  alias Vapor.{
    Store,
    Watch,
  }

  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor,
          restart: :permanent,
          shutdown: 500
        }
      end

      def set(key, value) when is_binary(key) do
        set([key], value)
      end

      def set(key, value) when is_list(key) do
        GenServer.call(__MODULE__, {:set, key, value})
      end

      def get(key, as: type) when is_binary(key) do
        get([key], as: type)
      end

      def get(key, as: type) when is_list(key) do
        case :ets.lookup(__MODULE__, key) do
          [] ->
            {:error, Vapor.NotFoundError}

          [{^key, value}] ->
            Vapor.Converter.apply(value, type)
        end
      end

      def get!(key, as: type) when is_binary(key) do
        get!([key], as: type)
      end

      def get!(key, as: type) when is_list(key) do
        case get(key, as: type) do
          {:ok, val} ->
            val

          {:error, error} ->
            raise error, {key, type}
        end
      end
    end
  end

  @doc """
  Starts a configuration store and any watches.
  """
  def start_link(module, plans, opts) do
    if opts[:name] do
      name = Keyword.fetch!(opts, :name)
      Supervisor.start_link(__MODULE__, {module, plans}, name: :"#{name}_sup")
    else
      raise Vapor.ConfigurationError, "must supply a `:name` argument"
    end
  end

  @doc """
  Stops the configuration store and any watches.
  """
  def stop(name) do
    Supervisor.stop(:"#{name}_sup")
  end

  def init({module, plans}) do
    children = [
      {Watch.Supervisor, [name: Watch.Supervisor.sup_name(module)]},
      {Store, {module, plans}},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

