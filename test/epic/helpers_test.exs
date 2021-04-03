defmodule Epic.HelpersTest do
  use ExUnit.Case

  import Epic.Tokenizer
  import Epic.Helpers
  import Epic.Context

  alias Epic.Match

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
    assert %{status: :ok, match: %{term: 'alpha'}} = parser.(string_ctx("alpha"))
  end

  test "ignore match" do
    parser = ignore(many(ascii_letter()))
    assert %{status: :ok, match: %{term: nil}} = parser.(string_ctx("alphabravo"))
  end

  test "ignore inner match" do
    foo = literal("foo")
    bar = literal("bar")
    baz = literal("baz")
    parser = sequence([ignore(foo), bar, ignore(baz)])

    result = parser.(string_ctx("foobarbaz"))
    assert %{status: :ok, match: %{term: ['bar']}} = result
  end

  test "ignore separators" do
    comma = char(?,)
    parser = sequence([digit(), many(sequence([ignore(comma), digit()]))])
    result = parser.(string_ctx("1,2,3,4,5"))

    # Note that because of the use of sequence which returns a list we get
    # each digit in a list so '2' rather than ?2
    assert %{status: :ok, match: %{term: [?1,['2','3','4','5']]}} = result
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

  test "parse sequence returning matches" do
    # The sequence parser takes an optional third argument that controls whether the
    # parser appends the %Match{} or the raw term
    parser = sequence([digit(), digit(), digit()], false)
    result = parser.(string_ctx("123"))
    assert %{status: :ok, match: %{term: [%Match{term: ?1}, %Match{term: ?2}, %Match{term: ?3}]}} = result
  end

  test "parsing sequence (flattened)" do
    comma = char(?,)
    parser = flatten(sequence([digit(), many(sequence([comma, digit()]))]))
    result = parser.(string_ctx("1,2,3"))
    assert %{status: :ok, match: %{term: [?1, ?,, ?2, ?,, ?3]}} = result
  end

end
