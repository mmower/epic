defmodule Epic.TokenizerTest do
  use ExUnit.Case

  alias Epic.Context

  import Epic.Tokenizer
  import Epic.Context, only: [string_ctx: 1]

  @empty_input string_ctx("")
  @single_a string_ctx("a")
  @single_A string_ctx("A")
  @single_1 string_ctx("1")
  @single_9 string_ctx("9")
  @single_tilde string_ctx("~")
  @single_nl string_ctx("\n")

  test "parses whitespace" do
    parser = whitespace()

    assert %Context{status: :error} = parser.(@empty_input)
    assert %Context{status: :error} = parser.(@single_a)

    assert %Context{status: :ok} = parser.(string_ctx(" "))
    assert %Context{status: :ok} = parser.(string_ctx("\t"))
  end

  test "parses a single character" do
    parser = char()
    assert %Context{status: :error} = parser.(@empty_input)

    assert %Context{
             status: :ok,
             match: %{term: ?a, position: %{line: 1, column: 1}},
             input: ""
           } = parser.(@single_a)
  end

  test "parse a digit" do
    parser = digit()
    assert %Context{status: :error} = parser.(@single_a)

    assert %Context{
             status: :ok,
             match: %{term: ?1, position: %{line: 1, column: 1}},
             input: ""
           } = parser.(@single_1)

    assert %Context{
             status: :ok,
             match: %{term: ?9, position: %{line: 1, column: 1}},
             input: ""
           } = parser.(@single_9)
  end

  test "parse a newline character" do
    parser = newline()
    assert %Context{status: :error} = parser.(@empty_input)
    assert %Context{status: :error} = parser.(@single_a)

    assert %Context{
             status: :ok,
             position: %{byte_offset: 1, line: 2, column: 1},
             match: %{term: ?\n, position: %{byte_offset: 0, line: 1, column: 1}},
             input: ""
           } = parser.(@single_nl)
  end

  test "parse an ASCII letter" do
    parser = ascii_letter()
    assert %Context{status: :error} = parser.(@single_1)
    assert %Context{status: :error} = parser.(@single_tilde)
    assert %Context{status: :ok, match: %{term: ?a, position: %{line: 1, column: 1}}, input: ""} = parser.(@single_a)
    assert %Context{status: :ok, match: %{term: ?A, position: %{line: 1, column: 1}}, input: ""} = parser.(@single_A)
  end

  test "parse char as string" do
    parser = string(ascii_letter())
    assert %Context{status: :ok, match: %{term: "a"}} = parser.(@single_a)
  end

  test "parse digit as integer" do
    parser = integer(digit())
    assert %Context{status: :ok, match: %{term: 9}} = parser.(@single_9)
  end

end
