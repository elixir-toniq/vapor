defmodule Vapor.ConfigurationTest do
  use ExUnit.Case, async: true

  alias Vapor.Configuration

  describe "creating and updating a configuration" do
    test "returns a list of commands to preform" do
      {configuration, actions} =
        %{
          0 => %{foo: 0},
          1 => %{foo: 1, bar: %{baz: 1}},
        }
        |> Configuration.new

      assert actions == [{:upsert, [:bar, :baz], 1}, {:upsert, [:foo], 1}]

      {new_config, actions} = Configuration.update(configuration, 0, %{foo: 2})
      assert actions == []

      {_config, actions} = Configuration.update(new_config, 1, %{foo: 3})
      assert actions == [{:upsert, [:foo], 3}, {:delete, [:bar, :baz]}]
    end
  end
end

