defmodule Epic.Helpers do
  @moduledoc """
  The Epic.Helpers module contains structural parsers such as `many`, `choice`, and `sequence` and
  utility parsers such as `ignore`, `label`, `transform`, `replace`, `map`, and `collect`.
  """
  alias Epic.{Context}

  import Epic.Match,
    only: [list_match: 1, append_match: 2, ignore_match: 0, terms_in_parsed_order: 1]


  @doc """
  The `label` combinator accepts a parser and a label string and returns a parser that calls the parser and, if it succeeds,
  labels it match according to calls its parser and, if that parser succeeds, labels the match.

  Example: label a phone number
    phone = label(many(digit()),"phone")
  """
  def label(parser, label) when is_function(parser) and is_binary(label) do
    fn %Context{} = ctx ->
      with %{status: :ok, match: match} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: %{match | label: label}}
      end
    end
  end

  @doc """
  The `ignore` parser calls its parser, but if the parser suceeds the match is replaced
  by a sentinel that will be recognised by structural parsers such as `sequence` and `many`
  causing them to ignore the match.

  Example: match digits ignoring '-' separators
    phone = many(choice([digit(),ignore(char(?-))]))
  """
  def ignore(parser) when is_function(parser) do
    fn %Context{} = ctx ->
      with %{status: :ok} = new_ctx <- parser.(ctx) do
        %{new_ctx | match: ignore_match()}
      end
    end
  end

  @doc """
  The `optional` combinator accepts a parser and returns a function that attempts to match the
  parser on the input. If the input matches the match is returned otherwise the original context
  is returned. Optional always succeeds.
  """
  def optional(parser) when is_function(parser) do
    fn %Context{} = ctx ->
      %{status: status} = parsed_ctx = parser.(ctx)
      if status == :ok do
        parsed_ctx
      else
        %{ctx | status: :ok}
      end
    end
  end

  @doc """
  The `times` parser calls its parser `n` times in a row.

  Example: match a 4 digit year
    year = times(digit(), 4)
  """
  def times(parser, n) when is_function(parser) and is_integer(n) do
    sequence(for _i <- 1..n, do: parser)
  end

  @doc """
  The `sequence` parser accepts a list of parsers and applies each in turn. The Match returned
  by `sequence` contains a list (either of Match or term items) of parsed items.

  The sequence parser takes a list of parsers and attempts to apply them in turn building a
  list-Match of results. The optional parameter extract_terms controls whether the sequence
  returns a list of Match structrs or a list of terms extracted from matches.
  """
  def sequence(parsers, extract_terms \\ true)
      when is_list(parsers) and is_boolean(extract_terms) do
    fn %Context{} = ctx ->
      sequence_parser(parsers, %{ctx | match: list_match(ctx.position)}, extract_terms)
    end
  end

  defp sequence_parser(parsers, ctx, extract_terms) do
    case parsers do
      [] ->
        %{ctx | match: terms_in_parsed_order(ctx.match)}

      [parser | rest] ->
        with %{status: :ok, match: %{term: term} = match} = parsed_ctx <- parser.(ctx) do
          if term == nil do
            # A nil term means the ignore() parser has been used to elide this from the output terms
            sequence_parser(rest, %{parsed_ctx | match: ctx.match}, extract_terms)
          else
            if extract_terms do
              sequence_parser(
                rest,
                %{parsed_ctx | match: append_match(ctx.match, match.term)},
                extract_terms
              )
            else
              sequence_parser(
                rest,
                %{parsed_ctx | match: append_match(ctx.match, match)},
                extract_terms
              )
            end
          end
        end
    end
  end

  @doc """
  The `choice` parser accepts a list of parsers and returns a parser that attempts to apply
  each in turn. If a parser matches then `choice` succeeds with that match. If all parsers
  fail to match then `choice` fails.

  Example: parse a number or a letter
    num_or_letter = choice([digit(), ascii_char()])
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
  The `many` parser takes a parser and returns a combinator that applies the parser in a greedy fashion
  returning a match containing a (potentially empty) list of terms matched.

  Note that the many parser never fails and will return an empty list if it does not match.
  """

  def many(parser, extract_terms \\ true)
      when is_function(parser) and is_boolean(extract_terms) do
    fn %Context{} = ctx ->
      with %{status: :ok, match: match} = result_ctx <-
             many_parser(parser, %{ctx | match: list_match(ctx.position)}, extract_terms) do
        %{result_ctx | match: terms_in_parsed_order(match)}
      end
    end
  end

  defp many_parser(parser, %Context{} = ctx, extract_terms) do
    case parser.(ctx) do
      %{:status => :error} ->
        ctx

      %{:status => :ok, match: %{term: term} = many_match} = parsed_ctx ->
        if term == nil do
          many_parser(parser, %{parsed_ctx | match: ctx.match}, extract_terms)
        else
          if extract_terms do
            many_parser(
              parser,
              %{parsed_ctx | match: append_match(ctx.match, many_match.term)},
              extract_terms
            )
          else
            many_parser(
              parser,
              %{parsed_ctx | match: append_match(ctx.match, many_match)},
              extract_terms
            )
          end
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
  def flatten(parser) when is_function(parser) do
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
