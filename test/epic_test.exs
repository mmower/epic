defmodule EpicTest do
  use ExUnit.Case
  doctest Epic

  test "greets the world" do
    assert Epic.hello() == :world
  end
end
