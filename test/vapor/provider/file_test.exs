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
end
