defmodule Vapor.ConfigTest do
  use ExUnit.Case, async: true

  defmodule TestConfig do
    use Vapor.Config

    def start_link do
      Vapor.start_link(__MODULE__, Vapor.Config.default(), name: __MODULE__)
    end
  end

  describe "get/2" do
    test "supports common transforms" do
      TestConfig.start_link()

      TestConfig.set("string", "string")
      TestConfig.set("int", "42")
      TestConfig.set("float", "3.2")
      TestConfig.set("true", "true")
      TestConfig.set("false", "false")

      assert TestConfig.get("string", as: :string) == {:ok, "string"}
      assert TestConfig.get("int", as: :int) == {:ok, 42}
      assert TestConfig.get("float", as: :float) == {:ok, 3.2}
      assert TestConfig.get("true", as: :bool) == {:ok, true}
      assert TestConfig.get("false", as: :bool) == {:ok, false}
    end

    test "returns errors if conversions fail" do
      TestConfig.start_link()

      TestConfig.set("string", "string")

      assert TestConfig.get("string", as: :int) == {:error, Vapor.ConversionError}
      assert TestConfig.get("string", as: :float) == {:error, Vapor.ConversionError}
      assert TestConfig.get("string", as: :bool) == {:error, Vapor.ConversionError}

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: :int)
      end

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: :float)
      end

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: :bool)
      end
    end

    test "allows custom conversions" do
      TestConfig.start_link()

      TestConfig.set("string", "string")

      assert TestConfig.get!("string", as: fn "string" -> {:ok, "bar"} end) == "bar"

      assert TestConfig.get("string",
               as: fn "string" ->
                 {:error, nil}
               end
             ) == {:error, Vapor.ConversionError}

      assert_raise Vapor.ConversionError, fn ->
        TestConfig.get!("string", as: fn "string" -> {:error, nil} end)
      end
    end
  end
end
