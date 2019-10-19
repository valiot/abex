defmodule AbexTest do
  use ExUnit.Case
  doctest Abex

  test "greets the world" do
    assert Abex.hello() == :world
  end
end
