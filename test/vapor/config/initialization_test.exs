defmodule Vapor.Config.InitializationTest do
  use ExUnit.Case, async: false

  defmodule AppConfig do
    use Vapor.Config

    alias Vapor.Config

    def start_link() do
      config =
        Config.default()
        |> Config.merge(Config.File.with_name("test/support/settings.json"))

      Vapor.start_link(__MODULE__, config, name: __MODULE__)
    end

    def init(config) do
      Application.put_env(:vapor, :config_test, [
        foo: config["foo"],
        baz: config["baz"],
      ])
      {:ok, config}
    end
  end

  defmodule CustomConfig do
    use Vapor.Config

    def start_link(config) do
      Vapor.start_link(__MODULE__, config, name: __MODULE__)
    end

    def init(_) do
      {:ok, %{"custom" => "custom loaded config"}}
    end
  end

  defmodule StopConfig do
    use Vapor.Config

    def start_link() do
      Vapor.start_link(__MODULE__, Vapor.Config.default(), name: __MODULE__)
    end

    def init(_) do
      {:stop, :cuz_i_said_so}
    end
  end

  setup do
    Application.delete_env(:vapor, :config_test)
  end

  describe "init/1" do
    test "can be overwritten" do
      assert Application.get_env(:vapor, :config_test) == nil

      AppConfig.start_link()

      assert Application.get_env(:vapor, :config_test) == [
        foo: "file foo",
        baz: "file baz"
      ]
    end

    test "loads whatever config is passed in" do
      config = Vapor.Config.default()

      CustomConfig.start_link(config)

      assert CustomConfig.get!("custom", as: :string) == "custom loaded config"
    end

    test "can halt the startup process" do
      Process.flag(:trap_exit, true)
      StopConfig.start_link()
      assert_receive {:EXIT, _, {:shutdown, {_, _, :cuz_i_said_so}}}
    end
  end
end
