defmodule EpicTest do
  use ExUnit.Case
  doctest Epic

  import Epic.Tokenizer
  import Epic.Helpers
  import Epic.Context, only: [string_ctx: 1]

  test "parses simple mathematical expression" do
    plus = label(replace(char(?+), :+), "+")
    minus = label(replace(char(?-), :-), "-")
    times = label(replace(char(?*), :*), "*")
    divide = label(replace(char(?/), :/), "/")

    operator = label(choice([plus, minus, times, divide]), "oper")
    int = label(integer(many(digit())), "int")
    expr = label(sequence([int, operator, int]), "expr")

    ctx = string_ctx("1+2")

    result = expr.(ctx)

    assert %{status: :ok} = result
  end
end
