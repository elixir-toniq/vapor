defmodule Vapor.Provider.GroupTest do
  use ExUnit.Case, async: false

  alias Vapor.Provider.{Group, Env}

  setup do
    System.delete_env("DB_HOST")

    :ok
  end

  test "groups return a grouped set of configs" do
    System.put_env("DB_HOST", "4369")

    provider = %Group{name: :primary_db, providers: [
      %Env{bindings: [
        {:host, "DB_HOST", map: &String.to_integer/1},
      ]},
    ]}

    assert Vapor.load!(provider) == %{primary_db: [host: 4369]}
  end

  # TODO - This test is not here to enforce this behaviour. In fact this really
  # isn't what we want. The test serves to specify the existing
  # semantics. We should change this eventually.
  test "groups with matching names are shallow merged" do
    System.put_env("DB_PORT", "4369")
    System.put_env("DB_HOST", "postgres")

    providers = [
      %Group{name: :primary_db, providers: [
        %Env{bindings: [
          host: "DB_HOST",
        ]},
      ]},
      %Group{name: :primary_db, providers: [
        %Env{bindings: [
          {:port, "DB_PORT", map: &String.to_integer/1},
        ]},
      ]},
    ]

    assert Vapor.load!(providers) == %{primary_db: [port: 4369]}
  end
end
