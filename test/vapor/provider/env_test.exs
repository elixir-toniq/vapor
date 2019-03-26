defmodule Vapor.Provider.EnvTest do
  use ExUnit.Case, async: false

  alias Vapor.Provider.Env

  setup do
    System.delete_env("APP_FOO")
    System.delete_env("APP_BAR")
    System.delete_env("FOO")
    System.delete_env("BAR")
    System.delete_env("BAZ")
  end

  test "with_prefix/1 loads all env variables with a given prefix" do
    System.put_env("APP_FOO", "env foo")
    System.put_env("APP_BAR", "env bar")

    plan = Env.with_prefix("APP")
    {:ok, envs} = Vapor.Provider.load(plan)
    assert envs[["foo"]] == "env foo"
    assert envs[["bar"]] == "env bar"
  end

  test "with_prefix/1 splits on _ into list" do
    System.put_env("APP_FOO_BAR", "env foo bar")
    plan = Env.with_prefix("APP")
    {:ok, envs} = Vapor.Provider.load(plan)
    assert envs[["foo", "bar"]] == "env foo bar"
  end

  describe "with_bindings/1" do
    test "must load all bindings or it returns an error" do
      System.put_env("FOO", "env foo")
      System.put_env("BAR", "env bar")

      plan =
        Env.with_bindings(
          foo: "FOO",
          bar: "BAR",
          baz: "BAZ"
        )

      assert {:error, _} = Vapor.Provider.load(plan)

      System.put_env("BAZ", "env baz")

      assert {:ok, envs} = Vapor.Provider.load(plan)

      assert envs["foo"] == "env foo"
      assert envs["bar"] == "env bar"
      assert envs["baz"] == "env baz"
    end
  end
end
