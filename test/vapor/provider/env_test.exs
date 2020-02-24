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

  test "can mark env provider as not required" do
    System.put_env("FOO", "FOO VALUE")

    provider = %Env{
      bindings: [
        foo: "FOO",
        bar: "BAR",
      ],
      required: false
    }
    assert {:ok, %{foo: "FOO VALUE"}} == Provider.load(provider)
  end

  test "translations can be provided inline" do
    System.put_env("FOO", "3")

    provider = %Env{
      bindings: [
        {:foo, "FOO", map: &String.to_integer/1},
      ]
    }
    assert {:ok, %{foo: 3}} == Provider.load(provider)
  end

  test "can specify default values" do
    System.put_env("FOO", "3")

    provider = %Env{
      bindings: [
        {:foo, "FOO", map: &String.to_integer/1},
        {:bar, "BAR", default: 1337},
        {:baz, "BAZ", default: false},
      ]
    }
    assert {:ok, %{foo: 3, bar: 1337, baz: false}} = Provider.load(provider)
  end

  test "can mark a value as non-required" do
    System.put_env("FOO", "3")

    provider = %Env{
      bindings: [
        {:foo, "FOO", map: &String.to_integer/1},
        {:bar, "BAR", required: false},
      ]
    }
    assert {:ok, %{foo: 3, bar: nil}} = Provider.load(provider)
  end
end
