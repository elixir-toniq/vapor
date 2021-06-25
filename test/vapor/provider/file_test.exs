defmodule Vapor.Provider.FileTest do
  use ExUnit.Case, async: false

  alias Vapor.Provider
  alias Vapor.Provider.File

  test "raises if the format is unknown" do
    assert_raise Vapor.FileFormatNotFoundError, fn ->
      %File{path: "test.test"} |> Provider.load()
    end
  end

  test "raises if the file is not found" do
    assert_raise Vapor.FileNotFoundError, fn ->
      %File{path: "test.toml"} |> Provider.load()
    end
  end

  describe "json" do
    test "reads in a file with a given mapping" do
      provider = %File{
        path: "test/support/settings.json",
        bindings: [
          foo: "foo",
          baz: "baz",
          boz: ["biz", "boz"],
        ]
      }

      assert {:ok, conf} = Provider.load(provider)
      assert conf.foo == "file foo"
      assert conf.baz == "file baz"
      assert conf.boz == "file biz boz"
    end

    test "returns an error if environment variables are missing" do
      provider = %File{
        path: "test/support/settings.json",
        bindings: [
          foo: "foo",
          bar: "bar",
          boz: ["boz"]
        ]
      }
      assert {:error, error} = Provider.load(provider)
      assert error == "Missing keys in file: bar, boz"
    end

    test "translations can be provided inline" do
      provider = %File{
        path: "test/support/settings.json",
        bindings: [
          {:foo, "foo", map: fn "file foo" -> 1337 end},
        ]
      }
      assert {:ok, %{foo: 1337}} == Provider.load(provider)
    end

    test "can specify default values" do
      provider = %File{
        path: "test/support/settings.json",
        bindings: [
          {:foo, "foo"},
          {:bar, ["some", "key"], default: 1337},
        ]
      }
      assert {:ok, %{foo: "file foo", bar: 1337}} = Provider.load(provider)
    end

    test "can mark a value as non-required" do
      provider = %File{
        path: "test/support/settings.json",
        bindings: [
          {:foo, "foo"},
          {:bar, ["some", "key"], required: false},
        ]
      }
      assert {:ok, %{foo: "file foo", bar: nil}} = Provider.load(provider)
    end
  end

  describe "toml" do
    test "reads in a file with a given mapping" do
      provider = %File{
        path: "test/support/settings.toml",
        bindings: [
          foo: "foo",
          bar: "bar",
          boz: ["biz", "boz"],
        ]
      }

      assert {:ok, conf} = Provider.load(provider)
      assert conf.foo == "foo toml"
      assert conf.bar == "bar toml"
      assert conf.boz == "biz boz toml"
    end

    test "returns an error if environment variables are missing" do
      provider = %File{
        path: "test/support/settings.toml",
        bindings: [
          foo: "foo",
          baz: "baz",
          boz: ["biz", "boz"],
        ]
      }
      assert {:error, error} = Provider.load(provider)
      assert error == "Missing keys in file: baz"
    end
  end

  describe "yaml/yml" do
    test "reads in a file with a given mapping" do
      provider = %File{
        path: "test/support/settings.yaml",
        bindings: [
          foo: "foo",
          bar: "bar",
          boz: ["biz", "boz"],
        ]
      }

      assert {:ok, conf} = Provider.load(provider)
      assert conf.foo == "foo yaml"
      assert conf.bar == "bar yaml"
      assert conf.boz == "biz boz yaml"
    end

    test "returns an error if environment variables are missing" do
      provider = %File{
        path: "test/support/settings.yml",
        bindings: [
          foo: "foo",
          baz: "baz",
          boz: ["biz", "boz"],
        ]
      }
      assert {:error, error} = Provider.load(provider)
      assert error == "Missing keys in file: baz"
    end
  end
end
