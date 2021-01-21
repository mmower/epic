defmodule Epic.PositionTest do
  use ExUnit.Case

  import Epic.Position
  alias Epic.Position

  test "beginning" do
    assert %Position{byte_offset: 0, column: 1, line: 1} = beginning()
  end

  test "increment" do
    pos = beginning() |> inc
    assert %Position{byte_offset: 1, column: 2, line: 1} = pos
  end

  test "increment twice" do
    pos = beginning() |> inc |> inc
    assert %Position{byte_offset: 2, column: 3, line: 1} = pos
  end

  test "increment past end of line" do
    pos = %Position{byte_offset: 1, column: 2, line: 1} |> inc(true)
    assert %Position{byte_offset: 2, column: 1, line: 2} = pos
  end
end
