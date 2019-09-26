defmodule Vapor.ConverterTest do
  use ExUnit.Case

  alias Vapor.Converter

  describe "apply" do
    test "converts an string into an integer" do
      assert Converter.apply("10", :int) == {:ok, 10}
    end

    test "converts an integer into an integer" do
      assert Converter.apply(10, :int) == {:ok, 10}
    end

    test "converts an string into an float" do
      assert Converter.apply("1.0", :float) == {:ok, 1.0}
    end

    test "converts an float into an float" do
      assert Converter.apply(1.0, :float) == {:ok, 1.0}
    end
  end
end
