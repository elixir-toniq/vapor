defmodule VaporTest do
  use ExUnit.Case, async: false
  doctest Vapor

  alias Vapor.Plan

  defmodule TestConfig do
    use Vapor

    def start_link(config \\ Plan.default()) do
      Vapor.start_link(__MODULE__, config, name: __MODULE__)
    end

    def stop do
      Vapor.stop(__MODULE__)
    end
  end

  describe "configuration" do
    test "can be overriden manually" do
      config = Plan.default()

      {:ok, _} = TestConfig.start_link(config)

      TestConfig.set("foo", "foo")

      assert TestConfig.get!("foo", as: :string) == "foo"
      assert TestConfig.get("blank", as: :string) == {:error, Vapor.NotFoundError}

      assert_raise Vapor.NotFoundError, fn ->
        TestConfig.get!("blank", as: :string)
      end

      TestConfig.stop()
    end

    test "can pull in the environment" do
      config =
        Plan.default()
        |> Plan.merge(Plan.Env.with_prefix("APP"))

      System.put_env("APP_FOO", "foo")
      System.put_env("APP_BAR", "bar")

      TestConfig.start_link(config)

      assert TestConfig.get!("foo", as: :string) == "foo"
      assert TestConfig.get!("bar", as: :string) == "bar"

      TestConfig.stop()
    end

    test "can be stacked" do
      config =
        Plan.default()
        |> Plan.merge(Plan.Env.with_prefix("APP"))
        |> Plan.merge(Plan.File.with_name("test/support/settings.json"))

      System.put_env("APP_FOO", "env foo")
      System.put_env("APP_BAR", "env bar")

      TestConfig.start_link(config)

      assert TestConfig.get!("foo", as: :string) == "file foo"
      assert TestConfig.get!("bar", as: :string) == "env bar"
      assert TestConfig.get!("baz", as: :string) == "file baz"

      TestConfig.stop()
    end

    test "path lists can be stacked" do
      config =
        Plan.default()
        |> Plan.merge(Plan.Env.with_prefix("APP"))
        |> Plan.merge(Plan.File.with_name("test/support/settings.json"))

      System.put_env("APP_BIZ_BOZ", "env biz boz")

      TestConfig.start_link(config)

      assert TestConfig.get!(["biz", "boz"], as: :string) == "file biz boz"

      TestConfig.stop()
    end

    test "manual config always takes precedence" do
      config =
        Plan.default()
        |> Plan.watch(Plan.Env.with_prefix("APP"), refresh_interval: 100)
        |> Plan.merge(Plan.File.with_name("test/support/settings.json"))

      System.put_env("APP_FOO", "env foo")
      System.put_env("APP_BAR", "env bar")
      System.put_env("APP_FIZ", "env fiz")

      TestConfig.start_link(config)

      TestConfig.set("foo", "manual foo")
      TestConfig.set("bar", "manual bar")

      System.put_env("APP_FOO", "foo take two")
      System.put_env("APP_BAR", "bar take two")
      System.put_env("APP_BAZ", "baz take two")
      System.put_env("APP_FIZ", "fiz take two")

      eventually(fn ->
        assert TestConfig.get!("foo", as: :string) == "manual foo"
        assert TestConfig.get!("bar", as: :string) == "manual bar"
        assert TestConfig.get!("baz", as: :string) == "file baz"
        assert TestConfig.get!("fiz", as: :string) == "fiz take two"
      end)

      TestConfig.stop()
    end

    test "sources can be watched for updates but still stack" do
      config =
        Plan.default()
        |> Plan.watch(Plan.Env.with_prefix("APP"), refresh_interval: 100)
        |> Plan.merge(Plan.File.with_name("test/support/settings.json"))

      System.put_env("APP_FOO", "env foo")
      System.put_env("APP_BAR", "env bar")

      TestConfig.start_link(config)

      assert TestConfig.get!("foo", as: :string) == "file foo"
      assert TestConfig.get!("bar", as: :string) == "env bar"
      assert TestConfig.get!("baz", as: :string) == "file baz"

      System.put_env("APP_FOO", "env foo second version")
      System.put_env("APP_BAR", "env bar second version")

      eventually(fn ->
        assert TestConfig.get!("foo", as: :string) == "file foo"
        assert TestConfig.get!("bar", as: :string) == "env bar second version"
      end)

      TestConfig.stop()
    end

    test "reads config from toml" do
      config =
        Plan.default()
        |> Plan.merge(Plan.File.with_name("test/support/settings.toml"))

      {:ok, _} = TestConfig.start_link(config)

      assert(TestConfig.get!("foo", as: :string) == "foo toml")
      assert(TestConfig.get!("bar", as: :string) == "bar toml")
      assert(TestConfig.get!(["biz", "boz"], as: :string) == "biz boz toml")

      TestConfig.stop()
    end

    test "reads config from yaml" do
      config =
        Plan.default()
        |> Plan.merge(Plan.File.with_name("test/support/settings.yaml"))

      {:ok, _} = TestConfig.start_link(config)

      assert(TestConfig.get!("foo", as: :string) == "foo yaml")
      assert(TestConfig.get!("bar", as: :string) == "bar yaml")
      assert(TestConfig.get!(["biz", "boz"], as: :string) == "biz boz yaml")

      TestConfig.stop()
    end
  end

  describe "get/2" do
    test "supports common transforms" do
      TestConfig.start_link()

      TestConfig.set("string", "string")
      TestConfig.set("int", "42")
      TestConfig.set("float", "3.2")
      TestConfig.set("true", "true")
      TestConfig.set("false", "false")

      assert TestConfig.get("string", as: :string) == {:ok, "string"}
      assert TestConfig.get("int", as: :int) == {:ok, 42}
      assert TestConfig.get("float", as: :float) == {:ok, 3.2}
      assert TestConfig.get("true", as: :bool) == {:ok, true}
      assert TestConfig.get("false", as: :bool) == {:ok, false}

      TestConfig.stop()
    end

    test "returns errors if conversions fail" do
      TestConfig.start_link()

      TestConfig.set("string", "string")

      assert TestConfig.get("string", as: :int) == {:error, Vapor.ConversionError}
      assert TestConfig.get("string", as: :float) == {:error, Vapor.ConversionError}
      assert TestConfig.get("string", as: :bool) == {:error, Vapor.ConversionError}

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: :int)
      end

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: :float)
      end

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: :bool)
      end

      TestConfig.stop()
    end

    test "allows custom conversions" do
      TestConfig.start_link()

      TestConfig.set("string", "string")

      assert TestConfig.get!("string", as: fn "string" -> {:ok, "bar"} end) == "bar"

      assert TestConfig.get(
               "string",
               as: fn "string" ->
                 {:error, nil}
               end
             ) == {:error, Vapor.ConversionError}

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: fn "string" -> {:error, nil} end)
      end

      TestConfig.stop()
    end
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
