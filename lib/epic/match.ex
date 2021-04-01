defmodule Epic.Match do
  @moduledoc """
  The Epic.Match module defines the Match record that contains a term which is an
  arbitrary value parsed from the input and the position that the match occurs at.
  """
  alias Epic.Position

  defstruct [:term, :position, :label]

  def empty_match(%Position{} = position), do: %Epic.Match{term: [], position: position}

  def char_match(char, %Position{} = position), do: %Epic.Match{term: char, position: position}

  def append_term(%Epic.Match{term: term} = match, item) when is_list(term) do
    %{match | term: [item | term]}
  end

  # @doc """
  # Given a character and position returns a Match for that character at that position.
  # """
  # def char_match(char, %Position{} = position) do
  #   %Epic.Match{term: char, position: position}
  # end

  # @doc """
  # Given a position returns a Match for the empty list at that position.
  # """
  # def list_match(%Position{} = position) do
  #   %Epic.Match{term: [], position: position}
  # end

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
