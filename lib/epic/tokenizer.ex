defmodule Epic.Tokenizer do
  @moduledoc """
  Provides a basic set of parsers for low-level terminals.
  """
  import Epic.Helpers
  import Epic.Match

  import Epic.Position, only: [inc: 2, line_col: 1]
  alias Epic.Context

  import Epic.Logger, only: [log_msg: 1]

  @doc """
  Matches a single digit character '0'…'9'
  """
  def digit(), do: satisfy(char(), fn char -> char in ?0..?9 end, fn char -> "Got: #{char} Expected: digit" end)

  @doc """
  Matches a single ASCII character 'a'…'z' or 'A'…'Z'
  """
  def ascii_letter(), do: satisfy(char(), fn char -> char in ?a..?z or char in ?A..?Z end, fn char -> "Got: #{char} Expected: ASCII letter, got #{char}" end)

  @doc """
  Matches a single space or tab characer
  """
  def whitespace(), do: satisfy(char(), fn char -> char in [?\s, ?\t, ?\r, ?\n] end, fn char -> "Got: #{char} Expected: whitespace" end)

  @doc """
  Matches a single new line character
  """
  def newline(), do: satisfy(char(), fn char -> char == ?\n end)

  def literal(s) when is_binary(s) do
    sequence(Enum.map(String.to_charlist(s), fn c -> char(c) end))
  end

  @doc """
  Returns sucess if the parser matches with the term converted into a string.
  """
  def string(parser) when is_function(parser) do
    fn ctx ->
      log_msg("string() -> #{line_col(ctx.position)} \"#{ctx.input}\"")
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
    fn ctx ->
      log_msg("integer() -> #{line_col(ctx.position)} \"#{ctx.input}\"")
      with %Context{status: :ok, match: match} = _new_ctx <- parser.(ctx) do
        case match.term do
          [] -> %{ctx | status: :error, message: "Cannot interpret as integer"}
          _ -> %{ctx | status: :ok, match: intify(match)}
        end
      end
    end
  end

  def eoi() do
    fn ctx ->
      log_msg("eoi")
      if ctx.input == "" do
        ctx
      else
        %{ctx | status: :error, message: "Expected end of input."}
      end
    end
  end

  @doc """
  The char parser matches a single, specified, character from the input.
  """
  def char(c) when is_integer(c) do
    satisfy(char(), fn char -> char == c end, fn char -> "Expected '#{List.to_string([c])}' but got '#{List.to_string([char])}'" end)
  end

  @doc """
  The char parser matches a single character from the input. If no character is available
  it will return a Context with status: :error. Otherwise it returns a Context with status
  :success and a Match with a single char term.
  """
  def char() do
    fn %Context{input: input} = ctx ->
      case input do
        "" ->
          %Context{ctx | :status => :error, :message => "Unexpected end of input"}

        <<char::utf8, rest::binary>> ->
          matches_char(ctx, char, rest)
      end
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
