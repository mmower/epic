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
    assert %Match{term: [], position: ^pos} = list_match(pos)
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
    # List matches are built in reverse, usually by sequence which
    # reverses the list when it's done
    match = %Match{term: [?_, ?o, ?o, ?f], position: beginning()}
    assert %Match{term: [?1, ?_, ?o, ?o, ?f]} = append_match(match, ?1)
  end

end
