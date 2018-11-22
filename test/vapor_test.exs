defmodule VaporTest do
  use ExUnit.Case, async: false
  doctest Vapor

  alias Vapor.Config

  defmodule TestConfig do
    use Vapor.Config

    def start_link(config) do
      Vapor.start_link(__MODULE__, config, name: __MODULE__)
    end
  end

  describe "configuration" do
    test "can be overriden manually" do
      config = Config.default()

      TestConfig.start_link(config)

      TestConfig.set("foo", "foo")

      assert TestConfig.get!("foo", as: :string) == "foo"
      assert TestConfig.get("blank", as: :string) == {:error, Vapor.NotFoundError}

      assert_raise Vapor.NotFoundError, fn ->
        TestConfig.get!("blank", as: :string)
      end
    end

    test "can pull in the environment" do
      config =
        Config.default()
        |> Config.merge(Config.Env.with_prefix("APP"))

      System.put_env("APP_FOO", "foo")
      System.put_env("APP_BAR", "bar")

      TestConfig.start_link(config)

      assert TestConfig.get!("foo", as: :string) == "foo"
      assert TestConfig.get!("bar", as: :string) == "bar"
    end

    test "can be stacked" do
      config =
        Config.default()
        |> Config.merge(Config.Env.with_prefix("APP"))
        |> Config.merge(Config.File.with_name("test/support/settings.json"))

      System.put_env("APP_FOO", "env foo")
      System.put_env("APP_BAR", "env bar")

      TestConfig.start_link(config)

      assert TestConfig.get!("foo", as: :string) == "file foo"
      assert TestConfig.get!("bar", as: :string) == "env bar"
      assert TestConfig.get!("baz", as: :string) == "file baz"
    end

    test "manual config always takes precedence" do
      config =
        Config.default()
        |> Config.merge(Config.Env.with_prefix("APP"))
        |> Config.merge(Config.File.with_name("test/support/settings.json"))

      System.put_env("APP_FOO", "env foo")
      System.put_env("APP_BAR", "env bar")

      TestConfig.start_link(config)

      TestConfig.set("foo", "manual foo")
      TestConfig.set("bar", "manual bar")

      assert TestConfig.get!("foo", as: :string) == "manual foo"
      assert TestConfig.get!("bar", as: :string) == "manual bar"
      assert TestConfig.get!("baz", as: :string) == "file baz"
    end

    test "reads config from toml" do
      config =
        Config.default()
        |> Config.merge(Config.File.with_name("test/support/settings.toml"))

      TestConfig.start_link(config)

      assert(TestConfig.get!("foo", as: :string) == "foo toml")
      assert(TestConfig.get!("bar", as: :string) == "bar toml")
    end

    test "reads config from yaml" do
      config =
        Config.default()
        |> Config.merge(Config.File.with_name("test/support/settings.yaml"))

      TestConfig.start_link(config)

      assert(TestConfig.get!("foo", as: :string) == "foo yaml")
      assert(TestConfig.get!("bar", as: :string) == "bar yaml")
    end
  end
end
