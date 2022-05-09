defmodule UbuntuTest do
  use ExUnit.Case
  doctest Ubuntu

  test "greets the world" do
    assert Ubuntu.hello() == :world
  end
end
