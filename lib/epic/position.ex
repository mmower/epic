defmodule Epic.Position do
  @moduledoc """
  The Epic.Position module defines a Position record that is used to determine where
  the parser is in the input stream including information used to keep track of lines.
  """
  defstruct [:byte_offset, :line, :column]

  @doc """
  Returns a Position initialized to the beginning of the byte input stream.
  """
  def beginning do
    %Epic.Position{byte_offset: 0, line: 1, column: 1}
  end

  @doc """
  Returns the next position for the input stream. Where newline is true
  this updates the line and column position accordingly.
  """
  def inc(%Epic.Position{} = position, newline \\ false) do
    if newline do
      %{
        position
        | byte_offset: position.byte_offset + 1,
          line: position.line + 1,
          column: 1
      }
    else
      %{
        position
        | byte_offset: position.byte_offset + 1,
          column: position.column + 1
      }
    end
  end

  defimpl String.Chars do
    def to_string(position) do
      "%Position{byte_offset: #{position.byte_offset}, line: #{position.line}, column: #{position.column}}"
    end
  end
end
