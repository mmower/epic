defmodule Epic.MatchTest do
  use ExUnit.Case

  import Epic.Match
  alias Epic.Match

  import Epic.Position

  test "construct simple match" do
    pos = beginning()
    assert %Match{term: ?a, position: ^pos} = char_match(?a, pos)
  end

  test "construct empty list match" do
    pos = beginning()
    assert %Match{term: [], position: ^pos} = empty_match(pos)
  end

  test "stringify match" do
    match = %Match{term: [?f, ?o, ?o, ?_, ?1], position: beginning()}
    assert %Match{term: "foo_1"} = match |> stringify
  end

  test "match to integer" do
    match = %Match{term: [?1, ?0, ?0, ?4, ?2], position: beginning()}
    assert %Match{term: 10042} = match |> intify
  end

  test "append to match" do
    match = %Match{term: [?f, ?o, ?o, ?_], position: beginning()}
    assert %Match{term: [?f, ?o, ?o, ?_, ?1]} = append(match, ?1)
  end

end
