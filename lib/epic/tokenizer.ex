defmodule Epic.Tokenizer do
  @moduledoc """
  Provides a basic set of parsers for low-level terminals.
  """
  import Epic.Helpers, only: [satisfy: 3, sequence: 1]
  import Epic.Match, only: [stringify: 1, intify: 1, char_match: 2]
  import Epic.Position, only: [inc: 2]

  alias Epic.Context

  defp char_to_string(char), do: List.to_string([char])

  @doc """
  Matches a single digit character '0'…'9'
  """
  def digit(), do: satisfy(char(), fn char -> char in ?0..?9 end, fn char -> "Got: #{char_to_string(char)} Expected: 0..9" end)

  @doc """
  Matches a single ASCII character 'a'…'z' or 'A'…'Z'
  """
  def ascii_letter(), do: satisfy(char(), fn char -> char in ?a..?z or char in ?A..?Z end, fn char -> "Got: #{char_to_string(char)} Expected: [a-zA-Z]" end)

  @doc """
  Matches a single space or tab characer
  """
  def whitespace(), do: satisfy(char(), fn char -> char in [?\s, ?\t, ?\r, ?\n] end, fn char -> "Got: #{char_to_string(char)} Expected: WS" end)

  @doc """
  Matches a single new line character
  """
  def newline(), do: satisfy(char(), fn char -> char == ?\n end, fn char -> "Got: #{char_to_string(char)} Expected: NL" end)

  def literal(s) when is_binary(s) do
    parsers =
      s
      |> String.to_charlist()
      |> Enum.map(&char/1)
    sequence(parsers)
  end

  @doc """
  Returns sucess if the parser matches with the term converted into a string.
  """
  def string(parser) when is_function(parser) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: stringify(match)}
      end
    end
  end

  @doc """
  Returns success if the parser matches with the term converted into an integer. Does
  not recognise '-' or '+' to specify integer sign only digits.
  """
  def integer(parser) when is_function(parser) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        case match.term do
          [] -> %{new_ctx | status: :error, message: "Cannot interpret as integer"}
          _ -> %{new_ctx | status: :ok, match: intify(match)}
        end
      end
    end
  end

  def eoi() do
    fn
      %Context{input: ""} = ctx ->
        ctx
      %Context{input: input} = ctx ->
        %{ctx | :status => :error, :message => "Expected end of input, found: #{input}"}
    end
  end

  @doc """
  The char parser matches a single, specified, character from the input.
  """
  def char(expected_char) when is_integer(expected_char) do
    satisfy(
      char(),
      fn actual_char ->
        actual_char == expected_char
      end,
      fn actual_char ->
        "Got: #{char_to_string(actual_char)}, Expected #{char_to_string(expected_char)}"
      end
    )
  end

  @doc """
  The char parser matches a single character from the input. If no character is available
  it will return a Context with status: :error. Otherwise it returns a Context with status
  :success and a Match with a single char term.
  """
  def char() do
    fn
      %Context{input: ""} = ctx ->
        %{ctx | :status => :error, :message => "Unexpected end of input"}
      %Context{input: input} = ctx ->
        <<char::utf8, rest::binary>> = input
        matches_char(ctx, char, rest)
    end
  end

  defp matches_char(%Context{position: position, parsed: parsed} = ctx, char, rest) do
    %{
      ctx
      | status: :ok,
        input: rest,
        parsed: parsed <> <<char>>,
        position: inc(position, char == ?\n),
        match: char_match(char, position)
    }
  end

end
