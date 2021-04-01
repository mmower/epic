defmodule Epic.Context do
  @moduledoc """
  Contexts are the fundamental structure in an Epic parser and are what is passed between
  the different combinators. The Context contains status, whether the last combinator was able
  to match or not, the input and parsed content, the position in the input stream, and a
  Match representing what has been matched so far.
  """
  import Epic.Position, only: [beginning: 0]

  defstruct [:status, :message, :parsed, :input, :position, :match]

  @spec string_ctx(String.t()) :: %Epic.Context{}

  @doc """
  Returns a new Context initialised with the given string as an input.
  """
  def string_ctx(s) when is_binary(s) do
    %Epic.Context{
      status: :ok,
      message: "",
      parsed: "",
      input: s,
      position: beginning(),
      match: nil
    }
  end

  defimpl String.Chars do
    def to_string(ctx) do
      "%Context{status: #{ctx.status}, message: #{ctx.message}, input: \"#{ctx.input}\" position: #{ctx.position}, match: #{ctx.match}, parsed: \"#{ctx.parsed}\"}"
    end
  end
end
