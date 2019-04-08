defmodule Vapor.Provider.DotenvTest do
  use ExUnit.Case, async: false

  alias Vapor.Provider.Dotenv

  describe "default/0" do
    setup do
      File.rm(".env")

      on_exit fn ->
        File.rm(".env")
      end

      :ok
    end

    test "reads the file in as variables" do
      contents = """
      FOO=foo
      BAR = bar
        BAZ     =this is a baz
      """
      File.write(".env", contents)

      plan = Dotenv.default()
      {:ok, envs} = Vapor.Provider.load(plan)
      assert envs[["foo"]] == "foo"
      assert envs[["bar"]] == "bar"
      assert envs[["baz"]] == "this is a baz"
    end

    test "returns correctly if the file doesn't exist" do
      plan = Dotenv.default()
      {:ok, envs} = Vapor.Provider.load(plan)
      assert envs == %{}
    end

    test "ignores any malformed data" do
      contents = """
      FOO=foo
      BAR
      =this is a baz
      """
      File.write(".env", contents)

      plan = Dotenv.default()
      {:ok, envs} = Vapor.Provider.load(plan)
      assert envs == %{["foo"] => "foo"}
    end

    test "ignores comment lines" do
      contents = """
      # This is a comment
      FOO=foo
      # BAR=bar
        # BAZ=comment with indentation
      """
      File.write(".env", contents)

      plan = Dotenv.default()
      {:ok, envs} = Vapor.Provider.load(plan)
      assert envs == %{["foo"] => "foo"}
    end
  end

  describe "with_file/1" do
    setup do
      File.rm(".env.dev")

      on_exit fn ->
        File.rm(".env.dev")
      end

      :ok
    end

    test "allows custom files" do
      contents = """
      FOO=foo
      BAR = bar
        BAZ     =this is a baz
      """
      File.write(".env.dev", contents)

      plan = Dotenv.with_file(".env.dev")
      {:ok, envs} = Vapor.Provider.load(plan)
      assert envs[["foo"]] == "foo"
      assert envs[["bar"]] == "bar"
      assert envs[["baz"]] == "this is a baz"
    end
  end
end

