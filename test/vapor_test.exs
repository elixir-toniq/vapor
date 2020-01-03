defmodule VaporTest do
  use ExUnit.Case, async: false
  doctest Vapor

  alias Vapor.Provider.{Env, File}

  setup do
    providers = [
      %Env{
        bindings: [
          foo: "APP_FOO",
          bar: "APP_BAR",
        ]
      }
    ]

    {:ok, providers: providers}
  end

  describe "load/2" do
    test "can pull in the environment", %{providers: providers} do
      System.put_env("APP_FOO", "foo")
      System.put_env("APP_BAR", "bar")

      {:ok, config} = Vapor.load(providers)

      assert config.foo == "foo"
      assert config.bar == "bar"
    end

    test "can provide translations", %{providers: providers} do
      System.put_env("APP_FOO", "foo")
      System.put_env("APP_BAR", "bar")
      translations = [
        foo: fn "foo" -> 1 end,
        bar: fn "bar" -> 2 end,
      ]

      {:ok, config} = Vapor.load(providers, translations)

      assert config.foo == 1
      assert config.bar == 2
    end

    test "configuration is layered" do
      System.put_env("APP_FOO", "foo")
      System.put_env("APP_BAR", "bar")

      providers = [
        %Env{
          bindings: [
            foo: "APP_FOO",
            bar: "APP_BAR",
          ]
        },
        %File{
          path: "test/support/settings.json",
          bindings: [
            foo: "foo",
            baz: "baz",
          ]
        }
      ]

      translations = [
        foo: fn "file foo" -> :success end,
      ]

      {:ok, config} = Vapor.load(providers, translations)

      assert config.foo == :success
      assert config.bar == "bar"
      assert config.baz == "file baz"
    end

    test "returns error if config is missing at the end", %{providers: providers} do
      System.put_env("APP_FOO", "foo")
      System.delete_env("APP_BAR")

      assert {:error, error} = Vapor.load(providers)
      assert match?(%Vapor.LoadError{}, error)
    end
  end

  describe "load!/2" do
    test "returns configuration", %{providers: providers} do
      System.put_env("APP_FOO", "foo")
      System.put_env("APP_BAR", "bar")

      config = Vapor.load!(providers)

      assert config.foo == "foo"
      assert config.bar == "bar"
    end

    test "raises errors", %{providers: providers} do
      System.put_env("APP_FOO", "foo")
      System.delete_env("APP_BAR")

      assert_raise Vapor.LoadError, fn ->
        Vapor.load!(providers)
      end
    end
  end
end

