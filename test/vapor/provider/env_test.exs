defmodule Vapor.Provider.EnvTest do
  use ExUnit.Case, async: false

  alias Vapor.Provider
  alias Vapor.Provider.Env

  setup do
    System.delete_env("FOO")
    System.delete_env("BAR")

    :ok
  end

  test "loads variables from the environment" do
    System.put_env("FOO", "FOO VALUE")
    System.put_env("BAR", "BAR VALUE")

    provider = %Env{bindings: [
      foo: "FOO",
      bar: "BAR",
    ]}
    assert {:ok, config} = Provider.load(provider)
    assert config.foo == "FOO VALUE"
    assert config.bar == "BAR VALUE"
  end

  test "returns an error if environment variables are missing" do
    provider = %Env{bindings: [
      foo: "FOO",
      bar: "BAR",
    ]}
    assert {:error, error} = Provider.load(provider)
    assert error == "ENV vars not set: BAR, FOO"
  end
end
