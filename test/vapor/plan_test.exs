defmodule Vapor.PlanTest do
  use ExUnit.Case, async: true

  alias Vapor.Provider.Env

  setup do
    System.delete_env("FOO")
    System.delete_env("BAR")

    :ok
  end

  defmodule Plan do
    @behaviour Vapor.Plan

    @impl true
    def config_plan do
      [
        %Env{
          bindings: [
            foo: "FOO"
          ]
        }
      ]
    end
  end

  defmodule SimplePlan do
    @behaviour Vapor.Plan

    def config_plan do
      %Env{
        bindings: [
          foo: "FOO"
        ]
      }
    end
  end

  test "plan modules can be loaded" do
    System.put_env("FOO", "FOO VALUE")
    System.put_env("BAR", "BAR VALUE")

    config = Vapor.load!(Plan)
    assert config.foo == "FOO VALUE"
  end

  test "plan modules can return a single provider" do
    System.put_env("FOO", "FOO VALUE")

    config = Vapor.load!(SimplePlan)
    assert config.foo == "FOO VALUE"
  end

  test "plan modules can be layered with other providers" do
    System.put_env("FOO", "FOO VALUE")
    System.put_env("BAR", "BAR VALUE")

    providers = [
      Plan,
      %Env{
        bindings: [bar: "BAR"]
      },
    ]

    config = Vapor.load!(providers)
    assert config.foo == "FOO VALUE"
    assert config.bar == "BAR VALUE"
  end

  test "modules that don't export config_plan/0 raise" do
    assert_raise ArgumentError, fn ->
      Vapor.load!(UnknownPlan)
    end
  end
end
