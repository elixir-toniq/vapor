defmodule Vapor.PlanTest do
  use ExUnit.Case, async: true

  alias Vapor.Provider.Env
  alias Vapor.Provider.Group

  setup do
    System.delete_env("FOO")
    System.delete_env("BAR")
    System.delete_env("BOOL")

    :ok
  end

  defmodule Plan do
    @behaviour Vapor.Plan

    @impl true
    def config_plan do
      [
        %Env{
          bindings: [
            foo: "FOO",
            bar: "BAR"
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

  defmodule DSLPlan do
    use Vapor.Planner

    def str_to_bool(str) do
      str == "true"
    end

    dotenv()

    config :env, env([
      {:foo, "FOO"},
      {:bar, "BAR"},
      {:bool, "BOOL", map: &str_to_bool/1},
    ])

    config :file, file("test/support/settings.json", [
      foo: "foo",
      baz: "baz",
      boz: ["biz", "boz"],
    ])

    config :plan, Plan
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

  test "modules can be nested" do
    System.put_env("FOO", "FOO VALUE")
    System.put_env("BAR", "BAR VALUE")

    provider = %Group{
      name: :g,
      providers: [Plan]
    }
    config = Vapor.load!(provider)
    assert config.g.foo == "FOO VALUE"
    assert config.g.bar == "BAR VALUE"
  end

  test "plans can be defined with the dsl" do
    System.put_env("FOO", "FOO VALUE")
    System.put_env("BAR", "BAR VALUE")
    System.put_env("BOOL", "true")

    config = Vapor.load!(DSLPlan)

    assert config.env[:foo] == "FOO VALUE"
    assert config.env[:bar] == "BAR VALUE"
    assert config.env.bool == true

    assert config.plan[:foo] == "FOO VALUE"
    assert config.plan[:bar] == "BAR VALUE"

    assert config.file[:foo] == "file foo"
    assert config.file[:baz] == "file baz"
    assert config.file[:boz] == "file biz boz"
  end
end
