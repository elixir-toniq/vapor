defmodule Vapor do
  @moduledoc """
  Vapor provides mechanisms for handling runtime configuration in your system.
  """

  alias Vapor.{
    Store,
    Watch
  }

  @type key :: String.t() | list()
  @type type :: :string | :int | :float | :bool
  @type value :: String.t() | integer | float | boolean

  @doc """
  Fetches a value from the config under the key provided. Accept a list forming a path of keys.
  You need to specify a type to convert the value into through the `as:` element.
  The accepted types are `:string`, `:int`, `:float` and `:bool`

  ## Example
      VaporExample.Config.get(:key)

  """
  @callback get(key :: key) :: term() | nil

  @doc """
  Set the value under the key in the store.

  ## Example
      VaporExample.Config.set(:key, "value")
  """
  @callback set(key :: key, value :: value) :: {:ok, value}

  @doc """
  Optional callback. Called when the configuration server starts. Passes the map
  of the reified values.
  """
  @callback init([{key, value}]) :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour Vapor

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor,
          restart: :permanent,
          shutdown: 500
        }
      end

      def set(key, value) do
        GenServer.call(__MODULE__, {:set, key, value})
      end

      def get(key) do
        case :ets.lookup(__MODULE__, key) do
          [] ->
            nil

          [{^key, value}] ->
            value
        end
      end

      def init(_values) do
        :ok
      end

      def handle_change(_values) do
        :ok
      end

      defoverridable [init: 1, handle_change: 1]
    end
  end

  @doc """
  Starts a configuration store and any watches.
  """
  def start_link(module, config, opts) do
    if opts[:name] do
      name = Keyword.fetch!(opts, :name)
      Supervisor.start_link(__MODULE__, {module, config}, name: :"#{name}_sup")
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

  def init({module, config}) do
    table_opts = [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
    ]

    ^module = :ets.new(module, table_opts)

    children = [
      {Watch.Supervisor, [name: Watch.Supervisor.sup_name(module)]},
      {Store, {module, config}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
