defmodule Vapor.Provider.DotenvTest do
  use ExUnit.Case, async: false

  alias Vapor.Provider.Dotenv

  setup do
    System.delete_env("FOO")
    System.delete_env("BAR")
    System.delete_env("BAZ")

    File.rm(".env")
    File.rm(".env.test")
    File.rm(".env.dev")

    on_exit fn ->
      File.rm(".env")
      File.rm(".env.test")
      File.rm(".env.dev")

      System.delete_env("FOO")
      System.delete_env("BAR")
      System.delete_env("BAZ")
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

    plan = %Dotenv{}
    assert {:ok, %{}} == Vapor.Provider.load(plan)
    assert System.get_env("FOO") == "foo"
    assert System.get_env("BAR") == "bar"
    assert System.get_env("BAZ") == "this is a baz"
  end

  test "returns correctly if the file doesn't exist" do
    plan = %Dotenv{}
    {:ok, envs} = Vapor.Provider.load(plan)
    assert envs == %{}
  end

  test "ignores any malformed data" do
    contents = """
    FOO=foo=
    BAR
    =this is a baz
    """
    File.write(".env", contents)

    plan = %Dotenv{}
    Vapor.Provider.load(plan)
    assert System.get_env("FOO") == "foo="
    assert System.get_env("BAR") == nil
    assert System.get_env("BAZ") == nil
  end

  test "ignores comment lines" do
    contents = """
    # This is a comment
    FOO=foo
    # BAR=bar
      # BAZ=comment with indentation
    """
    File.write(".env", contents)

    plan = %Dotenv{}
    Vapor.Provider.load(plan)
    assert System.get_env("FOO") == "foo"
    assert System.get_env("BAR") == nil
    assert System.get_env("BAZ") == nil
  end

  test "does not overwrite existing env variables by default" do
    contents = """
    # This is a comment
    FOO=foo
    BAR=bar
    """
    File.write(".env", contents)
    System.put_env("FOO", "existing foo")

    plan = %Dotenv{}
    Vapor.Provider.load(plan)
    assert System.get_env("FOO") == "existing foo"
    assert System.get_env("BAR") == "bar"
  end

  test "overwrites existing variables if specified" do
    contents = """
    # This is a comment
    FOO=foo
    BAR=bar
    """
    File.write(".env", contents)
    System.put_env("FOO", "existing")

    plan = %Dotenv{overwrite: true}
    Vapor.Provider.load(plan)
    assert System.get_env("FOO") == "foo"
    assert System.get_env("BAR") == "bar"
    assert System.get_env("BAZ") == nil
  end

  test "stacks multiple files together" do
    base_contents = """
    FOO=foo
    BAR=bar
    """
    File.write!(".env", base_contents)

    test_contents = """
    BAR=test bar
    BAZ=test baz
    """
    File.write!(".env.test", test_contents)

    System.put_env("FOO", "existing")

    Vapor.Provider.load(%Dotenv{})
    assert System.get_env("FOO") == "existing"
    assert System.get_env("BAR") == "test bar"
    assert System.get_env("BAZ") == "test baz"
  end

  test "allows custom files" do
    contents = """
    FOO=foo
    BAR = bar
      BAZ     =this is a baz
    """
    File.write(".env.dev", contents)

    plan = %Dotenv{filename: ".env.dev"}
    Vapor.Provider.load(plan)
    assert System.get_env("FOO") == "foo"
    assert System.get_env("BAR") == "bar"
    assert System.get_env("BAZ") == "this is a baz"
  end
end

