defmodule VaporTest do
  use ExUnit.Case, async: false
  doctest Vapor

  alias Vapor.Provider.Env

  defmodule TestConfig do
    use Vapor

    def start_link(config \\ Plan.default()) do
      Vapor.start_link(__MODULE__, config, name: __MODULE__)
    end

    def stop do
      Vapor.stop(__MODULE__)
    end
  end

  setup do
    plan = [
      %Env{
        bindings: [
          foo: "APP_FOO",
          bar: "APP_BAR",
        ]
      }
    ]

    config = %{plan: plan}

    {:ok, config: config}
  end

  test "can pull in the environment", %{config: config} do
    System.put_env("APP_FOO", "foo")
    System.put_env("APP_BAR", "bar")

    TestConfig.start_link(config)

    assert TestConfig.get(:foo) == "foo"
    assert TestConfig.get(:bar) == "bar"

    TestConfig.stop()
  end

  test "can provide translations", %{config: config} do
    System.put_env("APP_FOO", "foo")
    System.put_env("APP_BAR", "bar")
    translations = [
      foo: fn "foo" -> 1 end,
      bar: fn "bar" -> 2 end,
    ]

    TestConfig.start_link(Map.put(config, :translations, translations))

    assert TestConfig.get(:foo) == 1
    assert TestConfig.get(:bar) == 2

    TestConfig.stop()
  end

  test "calls init with the configuration map", %{config: config} do
    defmodule ConfigWithInit do
      use Vapor

      def start_link(config) do
        Vapor.start_link(__MODULE__, config, name: __MODULE__)
      end

      def init(values) do
        values = Map.put(values, :foo, 1337)
        values = Map.put(values, :other, "test")

        {:ok, values}
      end

      def stop do
        Vapor.stop(__MODULE__)
      end
    end

    System.put_env("APP_FOO", "foo")
    System.put_env("APP_BAR", "bar")
    translations = [
      foo: fn "foo" -> 1 end,
      bar: fn "bar" -> 2 end,
    ]

    ConfigWithInit.start_link(Map.put(config, :translations, translations))

    assert ConfigWithInit.get(:foo) == 1337
    assert ConfigWithInit.get(:other) == "test"

    ConfigWithInit.stop()
  end

  test "overrides always take precedence", %{config: config} do
    System.put_env("APP_FOO", "foo")
    System.put_env("APP_BAR", "bar")

    TestConfig.start_link(config)

    assert TestConfig.get(:foo) == "foo"
    assert TestConfig.get(:bar) == "bar"

    TestConfig.set(:foo, "new foo")
    TestConfig.set(:other, "new value")

    assert TestConfig.get(:foo) == "new foo"
    assert TestConfig.get(:other) == "new value"
  end
end

