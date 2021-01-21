defmodule Epic.Helpers do
  @moduledoc """
  The Epic.Helpers module contains the utility parsers choice/1, many/1, satisfy/2,
  transform/2, replace/2, map/2, collect/2.
  """
  alias Epic.Context
  import Epic.Match, only: [list_match: 1]

  @doc """
  The choice parser takes a list of parsers and returns a combinator which will try each
  parser in turn to see if it can match the input.
  """
  def choice(parsers) do
    fn ctx ->
      case parsers do
        [] ->
          %Context{ctx | :status => :error, :message => "No parser matches."}

        [parser | rest] ->
          with %{status: :error} <- parser.(ctx), do: choice(rest).(ctx)
      end
    end
  end

  # The many_parser parser is used to recursively iterate the list of parsers and collect
  # the results into a list.
  defp many_parser(parser, ctx) do
    case parser.(ctx) do
      %{:status => :error} -> ctx
      %{:status => :ok} = many_ctx ->
        # IO.puts "1st term = #{many_ctx.match.term} 2nd term = #{ctx.match.term}"
        many_ctx = %{many_ctx | match: %{ctx.match | term: [many_ctx.match.term | ctx.match.term]}}
        many_parser(parser, many_ctx)
    end
  end

  @doc """
  The many parser takes a parser and returns a combinator that applies the parser in a greedy fashion
  returning a match containing a (potentially empty) list of terms matched.

  Note that the many parser never fails and will return an empty list if it does not match.
  """

  def many(parser) do
    fn ctx ->
      with %{status: :ok, match: %{term: list} = match} = result_ctx <- many_parser(parser, %{ctx | match: list_match(ctx.position)}) do
        %{result_ctx | match: %{ match | term: Enum.reverse(list) } }
      end
    end
  end

  @doc """
  The update_context parser takes a parser and a function that accepts and returns a context and returns
  a combinator that runs the parser and, if it succeeds, passes the context to the function and returns
  the modified context. This is useful for modifying
  """
  def update_context(parser, updater) do
    fn ctx ->
      with %Context{status: :ok} = new_ctx <- parser.(ctx), do: updater.(new_ctx)
    end
  end

  @doc """
  The satisfy/2 parser takes a parser and an acceptor predicate and return a combinator that
  calls the parser and succeeds if the acceptor predicate accepts the resulting term.
  """
  def satisfy(parser, acceptor) do
    fn ctx ->
      with %Context{status: :ok, match: %{term: term}} = new_ctx <- parser.(ctx) do
        if acceptor.(term) do
          new_ctx
        else
          %{ctx | :status => :error, :message => "Term rejected"}
        end
      end
    end
  end

  @doc """
  The transform/2 parser takes a parser and a transformer function and returns a combinator.

  The combinator matches the input using the parser. If it succeeds the matching term is
  transformed using the transformer function and the resulting match is used.
  """
  def transform(parser, t_fn) when is_function(t_fn) do
    fn ctx ->
      with %Context{status: :ok, match: %{term: term} = match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | term: t_fn.(term)}}
      end
    end
  end

  @doc """
  The replace/2 parser takes a parser and a value and returns a combinator.

  The combinator matches the input using the parser. If the combinator suceeds
  the matched term is replaced by the value.
  """
  def replace(parser, replacement) do
    fn ctx ->
      with %Context{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | term: replacement}}
      end
    end
  end
end
