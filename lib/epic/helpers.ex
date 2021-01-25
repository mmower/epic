defmodule Epic.Helpers do
  @moduledoc """
  The Epic.Helpers module contains the utility parsers choice/1, many/1, satisfy/2,
  transform/2, replace/2, map/2, collect/2.
  """
  alias Epic.Context
  import Epic.Match, only: [empty_match: 1, append: 2]
  import Epic.Position, only: [line_col: 1]
  import Epic.Logger, only: [log: 2, log_msg: 1]

  @doc """
  The label parser adds a label to the annotation stack
  """
  def label(parser, annotation) when is_function(parser) do
    fn ctx ->
      log("label", ctx)
      with %{status: :ok, annotation: [_head | rest]} = new_ctx <- parser.(%{ctx | annotation: [annotation | ctx.annotation]}) do
        %{new_ctx | annotation: rest}
      end
    end
  end

  @doc """
  The ignore parsers runs the parser it is given but ignores the results of that parser
  """
  def ignore(parser) when is_function(parser) do
    fn ctx ->
      log("ignore", ctx)
      with %{status: :ok} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: ctx.match}
      end
    end
  end

  @doc """
  The sequence parser takes a list of parsers and attempts to apply them in turn building a
  List match of results.
  """
  def sequence(parsers, annotation \\ nil) when is_list(parsers) do
    fn ctx ->
      log("sequence(#{annotation})", ctx)
      sequence_parser(parsers, %{ctx | match: empty_match(ctx.position)})
    end
  end

  defp sequence_parser(parsers, ctx) do
    case parsers do
      [] ->
        ctx

      [parser | rest] ->
        with %{status: :ok, match: %{term: term}} = new_ctx <- parser.(ctx) do
          sequence_parser(rest, %{new_ctx | match: append(ctx.match, term)})
        end
    end
  end

  @doc """
  The choice parser takes a list of parsers and returns a combinator which will try each
  parser in turn to see if it can match the input.
  """
  def choice(parsers, annotation \\ nil) when is_list(parsers) do
    fn ctx ->
      log("choice(#{annotation})", ctx)
      case parsers do
        [] ->
          %Context{ctx | :status => :error, :message => "No parser matches at: \"#{ctx.input}\""}

        [parser | rest] ->
          with %{status: :error} <- parser.(ctx), do: choice(rest).(ctx)
      end
    end
  end

  @doc """
  The many parser takes a parser and returns a combinator that applies the parser in a greedy fashion
  returning a match containing a (potentially empty) list of terms matched.

  Note that the many parser never fails and will return an empty list if it does not match.
  """

  def many(parser, annotation \\ nil) when is_function(parser) do
    fn ctx ->
      log("many(#{annotation})", ctx)
      with %{status: :ok, match: %{term: list} = match} = result_ctx <-
             many_parser(parser, %{ctx | match: empty_match(ctx.position)}) do
        log("many(#{annotation}) -> result", result_ctx)
        %{result_ctx | match: %{match | term: Enum.reverse(list)}}
      end
    end
  end

  defp many_parser(parser, %Context{} = ctx) when is_function(parser) do
    case parser.(ctx) do
      %{:status => :error} ->
        log("many_parser(error)", ctx)
        ctx

      %{:status => :ok} = many_ctx ->
        log("many_parser(ok)", many_ctx)
        # IO.puts "1st term = #{many_ctx.match.term} 2nd term = #{ctx.match.term}"
        many_ctx = %{
          many_ctx
          | match: %{ctx.match | term: [many_ctx.match.term | ctx.match.term]}
        }

        many_parser(parser, many_ctx)
    end
  end

  @doc """
  The update_context parser takes a parser and a function that accepts and returns a context and returns
  a combinator that runs the parser and, if it succeeds, passes the context to the function and returns
  the modified context. This is useful for modifying
  """
  def update_context(parser, updater) when is_function(parser) and is_function(updater) do
    fn ctx ->
      with %Context{status: :ok} = new_ctx <- parser.(ctx), do: updater.(new_ctx)
    end
  end

  # @doc """
  # The satisfy/2 parser takes a parser and an acceptor predicate and return a combinator that
  # calls the parser and succeeds if the acceptor predicate accepts the resulting term.
  # """
  # def satisfy(parser, predicate, annotation \\ nil) when is_function(parser) and is_function(predicate) do
  #   fn ctx ->
  #     Logger.debug("satisfy(#{annotation}) -> #{ctx.input}")
  #     with %Context{status: :ok, match: %{term: term}} = new_ctx <- parser.(ctx) do
  #       if predicate.(term) do
  #         new_ctx
  #       else
  #         %{ctx | :status => :error, :message => "Term rejected"}
  #       end
  #     end
  #   end
  # end

  def satisfy(parser, predicate, reporter \\ fn x -> x end, annotation \\ nil) when is_function(parser) and is_function(predicate) and is_function(reporter) do
    fn ctx ->
      log("satisfy(#{annotation})", ctx)
      with %Context{status: :ok, match: %{term: term}} = new_ctx <- parser.(ctx) do
        if predicate.(term) do
          log_msg("\t succeeds: #{line_col(new_ctx.position)} \"#{new_ctx.input}\"")
          new_ctx
        else
          log_msg("\tfails: #{line_col(ctx.position)} \"#{ctx.input}\" #{reporter.(term)}")
          %{ctx | :status => :error, :message => reporter.(term)}
        end
      end
    end
  end

  @doc """
  The transform/2 parser takes a parser and a transformer function and returns a combinator.

  The combinator matches the input using the parser. If it succeeds the matching term is
  transformed using the transformer function and the resulting match is used.
  """
  def transform(parser, t_fn) when is_function(parser) and is_function(t_fn) do
    fn ctx ->
      log("transform()", ctx)
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
  def replace(parser, replacement) when is_function(parser) do
    fn ctx ->
      log("replace(#{replacement})", ctx)
      with %Context{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | term: replacement}}
      end
    end
  end
end
