defmodule VaporTest do
  use ExUnit.Case, async: false
  doctest Vapor

  alias Vapor.Provider
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
        Application.put_env(:test_config, :foo, values[:foo])
        Application.put_env(:test_config, :bar, values[:bar])

        :ok
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

    assert Application.get_env(:test_config, :foo) == 1
    assert Application.get_env(:test_config, :bar) == 2

    ConfigWithInit.stop()

    assert Application.delete_env(:test_config, :foo)
    assert Application.delete_env(:test_config, :bar)
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

  test "providers can be watched" do
    System.put_env("APP_FOO", "foo")
    System.put_env("APP_BAR", "bar")

    plan = [
      %Env{
        bindings: [
          foo: "APP_FOO",
          bar: "APP_BAR",
        ]
      },
      {%Provider.File{path: "test.json", bindings: [foo: "foo"]}, [watch: true, refresh_interval: 100]},
    ]

    translations = [
      foo: fn s -> String.upcase(s) end
    ]

    config = %{plan: plan, translations: translations}

    File.write!("test.json", Jason.encode!(%{foo: "foo"}))

    TestConfig.start_link(config)
    assert TestConfig.get(:foo) == "FOO"

    File.write!("test.json", Jason.encode!(%{foo: "new foo"}))

    eventually(fn ->
      assert TestConfig.get(:foo) == "NEW FOO"
    end)

    TestConfig.stop()

    File.rm("test.json")
  end

  defp eventually(f, count \\ 0) do
    f.()
  rescue
    e ->
      if count > 5 do
        reraise e, __STACKTRACE__
      else
        :timer.sleep(100)
        eventually(f, count + 1)
      end
  end
end

