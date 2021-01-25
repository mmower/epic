defmodule EpicTest do
  use ExUnit.Case
  doctest Epic

  import Epic.Tokenizer
  import Epic.Helpers
  import Epic.Context, only: [string_ctx: 1]
  import Epic.Logger, only: [log: 2, log_msg: 1]

  test "parses simple mathematical expression" do
    plus = replace(char(?+), :+)
    minus = replace(char(?-), :-)
    times = replace(char(?*), :*)
    divide = replace(char(?/), :/)

    operator = choice([plus, minus, times, divide], "parse operator +-*/")
    int = integer(many(digit()))
    expr = sequence([int, operator, int])

    ctx = string_ctx("1+2")

    log_msg( "Running assertions" )

    assert %{status: :ok} = expr.(ctx)
  end
end
