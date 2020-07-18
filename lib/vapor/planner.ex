defmodule Vapor.Planner do
  @moduledoc """
  This module provides a DSL for building configuration plans.

  ```elixir
  defmodule MyApp.Config do
    use Vapor.Planner

    dotenv()

    config :env, env([
      foo: "FOO",
      bar: "BAR",
    ])

    config :file, file("test/support/settings.json", [
      foo: "foo",
      baz: "baz",
      boz: ["biz", "boz"],
    ])

    config :kafka, MyApp.KafkaWorker
  end
  ```
  """
  alias Vapor.Provider.{Dotenv, Env, File, Group}

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :config_plan, accumulate: true)

      @behaviour Vapor.Plan

      import unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%{module: mod}) do
    plan = Module.get_attribute(mod, :config_plan)
    plan = Macro.escape(plan)

    quote do
      @impl Vapor.Plan
      def config_plan do
        unquote(plan)
      end

      defoverridable config_plan: 0
    end
  end

  defmacro dotenv do
    quote do
      @config_plan %Dotenv{}
    end
  end

  defmacro config(name, provider) do
    quote do
      @config_plan %Group{
        name: unquote(name),
        providers: [
          unquote(provider)
        ]
      }
    end
  end

  def env(bindings) do
    %Env{
      bindings: bindings
    }
  end

  def file(path, bindings) do
    %File{
      path: path,
      bindings: bindings
    }
  end
end
