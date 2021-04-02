defmodule Epic.Helpers do
  @moduledoc """
  The Epic.Helpers module contains the utility parsers label/2, choice/1, many/1, satisfy/2,
  transform/2, replace/2, map/2, collect/2.
  """
  alias Epic.{Context}
  import Epic.Match, only: [list_match: 1, append_match: 2]

  @doc """
  The label parser labels the current matching value.
  """
  def label(parser, label) do
    fn %Context{} = ctx ->
      with %{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | label: label}}
      end
    end
  end

  @doc """
  The ignore parsers runs the parser it is given but ignores the results of that parser
  """
  def ignore(parser) do
    fn %Context{} = ctx ->
      with %{status: :ok} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: ctx.match}
      end
    end
  end

  @doc """
  The sequence parser takes a list of parsers and attempts to apply them in turn building a
  List match of results.
  """
  def sequence(parsers, collapse \\ true) when is_list(parsers) do
    fn %Context{} = ctx ->
      sequence_parser(parsers, %{ctx | match: list_match(ctx.position)}, collapse)
    end
  end

  def reorder_matches(%{match: %{term: term} = match} = ctx) when is_list(term) do
    %{ctx | match: %{match | term: Enum.reverse(term)}}
  end

  defp sequence_parser(parsers, ctx, collapse) do
    case parsers do
      [] ->
        reorder_matches(ctx)

      [parser | rest] ->
        with %{status: :ok, match: match} = parsed_ctx <- parser.(ctx) do
          case collapse do
            true -> sequence_parser(rest, %{parsed_ctx | match: append_match(ctx.match, match.term)}, collapse)
            false -> sequence_parser(rest, %{parsed_ctx | match: append_match(ctx.match, match)}, collapse)
          end
        end
    end
  end

  @doc """
  The choice parser takes a list of parsers and returns a combinator which will try each
  parser in turn to see if it can match the input.
  """
  def choice(parsers) when is_list(parsers) do
    fn %Context{} = ctx ->
      choice_parser(parsers, ctx)
    end
  end

  defp choice_parser(parsers, ctx) do
    case parsers do
      [] ->
        %Context{ctx | :status => :error, :message => "No parser matches at: \"#{ctx.input}\""}

      [parser | rest] ->
        with %{status: :error} <- parser.(ctx), do: choice_parser(rest, ctx)
    end
  end

  @doc """
  The many parser takes a parser and returns a combinator that applies the parser in a greedy fashion
  returning a match containing a (potentially empty) list of terms matched.

  Note that the many parser never fails and will return an empty list if it does not match.
  """

  def many(parser, collapse \\ true) do
    fn %Context{} = ctx ->
      with %{status: :ok, match: %{term: list} = match} = result_ctx <-
             many_parser(parser, %{ctx | match: list_match(ctx.position)}, collapse) do
        %{result_ctx | match: %{match | term: Enum.reverse(list)}}
      end
    end
  end

  defp many_parser(parser, %Context{} = ctx, collapse) do
    case parser.(ctx) do
      %{:status => :error} ->
        ctx

      %{:status => :ok, match: many_match} = parsed_ctx ->
        case collapse do
          true -> many_parser(parser, %{parsed_ctx | match: append_match(ctx.match, many_match.term)}, collapse)
          false -> many_parser(parser, %{parsed_ctx | match: append_match(ctx.match, many_match)}, collapse)
        end
    end
  end

  @doc """
  The update_context parser takes a parser and a function that accepts and returns a context and returns
  a combinator that runs the parser and, if it succeeds, passes the context to the function and returns
  the modified context. This is useful for modifying
  """
  def update_context(parser, updater) when is_function(parser) and is_function(updater) do
    fn %Context{} = ctx ->
      with %Context{status: :ok} = new_ctx <- parser.(ctx) do
        updater.(new_ctx)
      end
    end
  end

  @doc """
  The flatten/1 parser takes a parser and "flattens" it results.
  """
  def flatten(parser) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: %{term: terms} = match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | term: List.flatten(terms)}}
      end
    end
  end

  # @doc """
  # The satisfy/2 parser takes a parser and an acceptor predicate and return a combinator that
  # calls the parser and succeeds if the acceptor predicate accepts the resulting term.
  # """
  def satisfy(parser, predicate, err_msg_fn \\ fn x -> x end)
      when is_function(parser) and is_function(predicate) and is_function(err_msg_fn) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: %{term: term}} = new_ctx <- parser.(ctx) do
        if predicate.(term) do
          new_ctx
        else
          %{ctx | :status => :error, :message => err_msg_fn.(term)}
        end
      end
    end
  end

  @doc """
  The transform/2 parser takes a parser and a transformer function and returns a combinator.

  The combinator matches the input using the parser. If it succeeds the matching term is
  transformed using the transformer function and the resulting match is used.
  """
  def transform(parser, transformer)
      when is_function(parser) and is_function(transformer) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: %{term: term} = match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | term: transformer.(term)}}
      end
    end
  end

  @doc """
  The replace/2 parser takes a parser and a value and returns a combinator.

  The combinator matches the input using the parser. If the combinator suceeds
  the matched term is replaced by the value.
  """
  def replace(parser, replacement) when is_function(parser) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | term: replacement}}
      end
    end
  end
end
