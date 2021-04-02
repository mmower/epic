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
    parser = sequence([expr,eoi])

    ctx = string_ctx("1+2")

    result = parser.(ctx)

    assert %{status: :ok} = result
  end

  test "parses series of strings" do
    str = many(ascii_letter())
    comma = label(replace(char(?,), :comma), "comma")
    strings = sequence([char(?"),sequence([str,many(sequence([comma,str]))]),char(?")])
    parser = sequence([strings,eoi])
    result = parser.(string_ctx("\"many,are,called,few,are,choosen\""))

    IO.puts inspect(result)
    assert %{status: :ok} = result
  end
end
