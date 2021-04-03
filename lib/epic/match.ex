defmodule Epic.Match do
  @moduledoc """
  The Epic.Match module defines the Match record that contains a term which is an
  arbitrary value parsed from the input and the position that the match occurs at.
  """
  alias Epic.Position

  defstruct term: nil, position: nil, label: nil

  @doc """
  Given a Position return a new Match at that position to hold a list of sub-
  matches.
  """
  def list_match(%Position{} = position), do: %Epic.Match{term: [], position: position}

  @doc """
  Given a character and a Position, returns a Match for that character at that position
  """
  def char_match(char, %Position{} = position), do: %Epic.Match{term: char, position: position}

  @doc """
  Given a Match with a list-based term and an item returns a new Match with the item
  pre-pended to the list.
  """
  def append_match(%Epic.Match{term: terms} = match, new_match) when is_list(terms) do
    %{match | term: [new_match | terms]}
  end

  @doc """
  Returns a Match that should be ignored.
  """
  def ignore_match(), do: %Epic.Match{}

  @doc """
  The natural way to build lists in Elixir is by pre-pending items hence we need a way
  to reverse them to form a natural order when building up lists.
  """
  def terms_in_parsed_order(%Epic.Match{term: terms} = match) when is_list(terms) do
    %{match | term: Enum.reverse(terms)}
  end

  @doc """
  Given a Match with a term that can be converted into a string (principally a char or a
  list of chars) returns a Match where the term has been converted to a string.
  """
  def stringify(%Epic.Match{term: term} = match) do
    if is_list(term) do
      %{match | term: to_string(term)}
    else
      %{match | term: to_string([term])}
    end
  end

  @doc """
  Given a Match with a term that can be converted into a string (a list of chars) and from
  there an integer (corresponding to digits) returns a Match whose term is that integer.
  """
  def intify(%Epic.Match{} = match) do
    with %{term: term} <- stringify(match) do
      %{match | term: String.to_integer(term)}
    end
  end

  defimpl String.Chars do
    def to_string(match) do
      "%Match{term: #{match.term}, position: #{match.position}}"
    end
  end

end
