defmodule VaporTest do
  use ExUnit.Case
  doctest Vapor

  test "greets the world" do
    assert Vapor.hello() == :world
  end
end
