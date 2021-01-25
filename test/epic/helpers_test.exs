defmodule Epic.HelpersTest do
  use ExUnit.Case

  import Epic.Tokenizer
  import Epic.Helpers
  import Epic.Context

  test "test choice fails on empty input" do
    parser = choice([ascii_letter(), digit()])
    assert %{status: :error} = parser.(string_ctx(""))
  end

  test "choice fails on invalid input" do
    parser = choice([ascii_letter(), digit()])
    assert %{status: :error} = parser.(string_ctx("~"))
  end

  test "choice determines between letter and digit" do
    parser = choice([ascii_letter(), digit()])
    assert %{status: :ok, match: %{term: ?a}} = parser.(string_ctx("a"))
    assert %{status: :ok, match: %{term: ?1}} = parser.(string_ctx("1"))
  end

  test "many with no matches" do
    parser = many(ascii_letter())
    assert %{status: :ok, match: %{term: []}} = parser.(string_ctx(""))
  end

  test "many with a single match" do
    parser = many(ascii_letter())
    ctx = string_ctx("f")
    assert %{status: :ok, match: %{term: [?f]}} = parser.(ctx)
  end

  test "many takes multiple letters" do
    parser = many(ascii_letter())
    assert %{status: :ok, match: %{term: [?f, ?o, ?o]}} = parser.(string_ctx("foo"))
  end

  test "replace match" do
    parser = many(ascii_letter()) |> replace([?b, ?a, ?r])
    assert %{status: :ok, match: %{term: [?b, ?a, ?r]}} = parser.(string_ctx("foo"))
  end

  test "transform match" do
    parser = many(ascii_letter()) |> transform( fn term -> Enum.reverse(term) end)
    assert %{status: :ok, match: %{term: [?f, ?o, ?o]}} = parser.(string_ctx("oof"))
  end

  test "parse literal" do
    parser = literal("alpha")
    assert %{status: :ok, match: %{term: [?a, ?l, ?p, ?h, ?a]}} = parser.(string_ctx("alpha"))
  end

  test "ignore match" do
    parser = ignore(many(ascii_letter()))
    assert %{status: :ok, match: nil} = parser.(string_ctx("alphabravo"))
  end

  test "parse sequence" do
    parser = sequence([ascii_letter(), digit(), ascii_letter(), digit(), ascii_letter()])
    assert %{status: :ok, match: %{term: [?f, ?1, ?o, ?2, ?o]}} = parser.(string_ctx("f1o2o"))
  end

  test "parse sequence of choices" do
    parser = sequence([choice([ascii_letter(), digit()]), choice([ascii_letter(), digit()]), choice([ascii_letter(), digit()])])
    assert %{status: :ok, match: %{term: [?f, ?1, ?o]}} = parser.(string_ctx("f1o"))
    assert %{status: :ok, match: %{term: [?f, ?o, ?o]}} = parser.(string_ctx("foo"))
    assert %{status: :ok, match: %{term: [?1, ?2, ?3]}} = parser.(string_ctx("123"))
  end

end
