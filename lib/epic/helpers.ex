defmodule Epic.Helpers do
  alias Epic.Parser

  @type label :: String.t
  @type count :: Integer.t
  @type parser_list :: list
  @type match_pred :: (any -> boolean)
  @type error_message_generator :: (any -> String.t)
  @type transformer :: (any -> any)

  @moduledoc """
  The Epic.Helpers module contains structural parsers such as `many`, `choice`, and `sequence` and
  utility parsers such as `ignore`, `label`, `transform`, `replace`, `map`, and `collect`.
  """
  alias Epic.{Context}

  import Epic.Match,
    only: [list_match: 1, append_match: 2, ignore_match: 0, terms_in_parsed_order: 1]

  @doc """
  `label` is used to add a label to the match returned by another parser.

  The `label/2` combinator accepts a combinator `c` and label `l` and returns a parser `p*` that accepts a
  `Epic.Context` `ctx`.

  When `p*` is invoked it calls `p.(ctx)`. If `p` succeeds with `Epic.Match` `m` then `p*`
  succeeds with `m` labelled with `l`.

  Example: label a phone number
  ```
    phone = label(many(digit()), "phone")
  ```
  """

  @spec label(Parser.combinator(), label) :: Parser.parser()
  def label(p, l) when is_function(p) and is_binary(l) do
    fn %Context{} = ctx ->
      with %{status: :ok, match: match} = new_ctx <- p.(ctx) do
        %{new_ctx | match: %{match | label: l}}
      end
    end
  end

  @doc """
  `ignore` uses a parser to match but discards the matched term.

  The `ignore/1` combinator accepts a parser `p` and creates a parser
  `p*` that accepts a `Epic.Context` `ctx`.

  When `p*` is invoked it calls `p.(ctx)`. If `p` succeeds with `Epic.Match` `m`
  then p* succeeds with `m` replaced with an _ignore_ sentinel value.

  Note that the `sequence/2` and `many/2` combinators automatically ignore
  such matches.

  Example: match digits ignoring '-' separators
  ```
    phone = many(choice([digit(), ignore(char(?-))]))
  ```
  """
  @spec ignore(Parser.combinator()) :: Parser.parser()
  def ignore(p) when is_function(p) do
    fn %Context{} = ctx ->
      with %{status: :ok} = new_ctx <- p.(ctx) do
        %{new_ctx | match: ignore_match()}
      end
    end
  end

  @doc """
  `optional` allows for 0 or 1 matches to succeed.

  The `optional/1` combinator accepts a parser `p` and returns a parser `p*` that accepts
  a `Epic.Context` `ctx`.

  When `p*` is invoked it calls `p.(ctx)`. If `p` succeeds with `Epic.Match` `m` then
  `p*` succeeds with `m`. If `p` fails then `p*` succeeds with the original `ctx` (and, hence
  position information) preserved.

  Note: `optional/1` always succeeds.

  Example: leading +/- is optional to a number
  ```
  number = sequence([optional(choice([char(?+), char(?-)])), …])
  ```
  """
  @spec optional(Parser.combinator()) :: Parser.parser()
  def optional(p) when is_function(p) do
    fn %Context{} = ctx ->
      %{status: status} = parsed_ctx = p.(ctx)

      if status == :ok do
        parsed_ctx
      else
        %{ctx | status: :ok}
      end
    end
  end

  @doc """
  `times` matches the same parser a specified number of times returning a list of
  matches as per `sequence/2`

  The `times/2` combinator accepts a parser `p` & number `n` and returns a parser `p*`
  that accepts a `Epic.Context`.

  When `p*` is invoked it calls `p.(ctx)` `n` times passing the returned context from
  each invocation as the context for the next.

  Example: match a 4 digit year
    year = times(digit(), 4)

  Note: `times/1` is implemented in terms of `sequence/2`
  """
  @spec times(Parser.combinator(), count()) :: Parser.parser()
  def times(p, n) when is_function(p) and is_integer(n) do
    sequence(for _i <- 1..n, do: p)
  end

  @doc """
  `sequence` is used to match a series of parsers in turn.

  The `sequence/1` combinator accepts a list of parsers `[p1, p2, …, pn]` and returns
  a parser `p*` that accepts a `Epic.Context` `ctx`.

  When `p*` is invoked it chains together calls as `p1.(ctx) |> p2 |> … |> pn` and
  succeeds if all of `p1`, … `pn` succeed with matching term `[t1, t2,  … tn]`.

  Example: parse a name
  ```
    sequence([given_name, whitespace, family_name])
  ```

  Note: passing an empty list of parsers will result in an error.
  """

  @spec sequence(parser_list) :: Parser.parser()

  def sequence(parsers)

  def sequence(parsers) when is_list(parsers) do
    fn %Context{} = ctx ->
      sequence_parser(parsers, %{ctx | match: list_match(ctx.position)})
    end
  end

  def sequence([]) do
    raise "You must supply at least one parser to sequence"
  end

  defp sequence_parser(parsers, ctx) do
    case parsers do
      [] ->
        %{ctx | match: terms_in_parsed_order(ctx.match)}

      [parser | rest] ->
        with %{status: :ok, match: %{term: term} = match} = parsed_ctx <- parser.(ctx) do
          if term == nil do
            # A nil term means the ignore() parser has been used to elide this from the output terms
            sequence_parser(rest, %{parsed_ctx | match: ctx.match})
          else
            sequence_parser(
              rest,
              %{parsed_ctx | match: append_match(ctx.match, match.term)}
            )
          end
        end
    end
  end

  @doc """
  `choice` is used to select from among a number of possible parsers.

  The `choice/1` combinator accepts a list of parsers `[p1, p2, …, pn]` and returns
  a parser `p*` that accepts a `Epic.Context` `ctx`.

  When `p*` is invoked it invokes each of `p1.(ctx)`, `p2.(ctx)`, …, `pn.(ctx)` in
  turn until one of them succeeds with `Epic.Match` `m`.

  If `p` matches then `p*` matches with term `m` otherwise `p*` fails.

  Example: parse a number or a letter
  ```
    num_or_letter = choice([digit(), ascii_char()])
  ```

  Note: passing an empty list of parsers to `choice` will result in an error.
  """

  @spec choice(parser_list()) :: Parser.parser()

  def choice(parsers) when is_list(parsers) do
    fn %Context{} = ctx ->
      choice_parser(parsers, ctx)
    end
  end

  def choice([]) do
    raise("You must supply at least one parser to choice")
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
  `many` is used to greedy match a parser zero or more times.

  The `many/1` combinator accepts a parser `p` and returns a parser `p*` that accepts a `Epic.Context` `ctx`.

  When `p*` is invoked it creates an empty list of matched terms `l` then repeatedly invokes `p.(ctx)`.

  If `p` succeeds with `Epic.Match` `m` then the term `t` of m is appended to `l`.

  On each the subsequent invocation the resulting `ctx` from the last invocation is passed as the input `ctx` of
  the next.

  If `p` fails then `p*` succeeds with matching term `l` consisting of `[t1, t2, …, tn]`. If `p` never succeeds
  then `l` consists of `[]`.

  Note: parsers generated by many always succeed.

  Example: greedy match zero or more digits
  ```
      many(digit())
  ```
  """

  @spec many(Parser.combinator()) :: Parser.parser()

  def many(parser) when is_function(parser) do
    fn %Context{} = ctx ->
      with %{status: :ok, match: match} = result_ctx <-
             many_parser(parser, %{ctx | match: list_match(ctx.position)}) do
        %{result_ctx | match: terms_in_parsed_order(match)}
      end
    end
  end

  defp many_parser(parser, %Context{} = ctx) do
    case parser.(ctx) do
      %{:status => :error} ->
        ctx

      %{:status => :ok, match: %{term: term} = many_match} = parsed_ctx ->
        if term == nil do
          many_parser(parser, %{parsed_ctx | match: ctx.match})
        else
          many_parser(
            parser,
            %{parsed_ctx | match: append_match(ctx.match, many_match.term)}
          )
        end
    end
  end

  @doc """
  `update_context` allows for arbitrary modification of the context. Use with caution. Usually you want
  `transform` or `replace` instead.

  The `update_context/2` combinator accepts a parser `p` and transformer `t` and returns a parser `p*`
  that accepts a `Epic.Context` `ctx` and returns a

  When `p*` is invoked it calls `p.(ctx)` and return `ctx*`. If `p*` succeeds then `p*` succeeds returning
  returning a context that
  is the result of `t.(ctx)`

  Note: `t_fn` must return a valid `Context` or an error will occur.
  """

  @type updater :: (%Context{} -> %Context{})

  @spec update_context(Parser.combinator(), updater()) :: Parser.parser()

  def update_context(p, t) when is_function(p) and is_function(t) do
    fn %Context{} = ctx ->
      with %Context{status: :ok} = new_ctx <- p.(ctx) do
        t.(new_ctx)
      end
    end
  end

  @doc """
  `flatten` flattens the result of parsing nested structures for example combining `sequence` and
  `many`.

  The `flatten/1` combinator accepts a combinator `p` and returns a parser `p*` that accepts a `Context`.

  `p*` calls `p` with the `Context`. If `p` succeeds with matching term list `m` then `p*`
  succeeds with a term list that is `m` flattened. If `flatten` is used with a parser that
  does not return a list match an error will occur.
  """

  @spec flatten(Parser.combinator()) :: Parser.parser()

  def flatten(p) when is_function(p) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: %{term: terms} = match} = new_ctx <- p.(ctx) do
        %{new_ctx | match: %{match | term: List.flatten(terms)}}
      end
    end
  end

  @doc """
  `satisfy` is used to apply further checks to terms returned by a parser usually to implement
  limits on a more general parser, e.g. that a char is in a given range.

  `satisfy` accepts a parser `p`, a predicate `pred_fn` and an optional `err_msg_fn` and returns
  a parser `p*` that accepts a `Epic.Context` `ctx`.

  `p*` calls `p.(ctx)`. If `p` succeeds with matching term `t` then `t` is passed to `pred_fn`. If
  `pred_fn` returns true then `p*` succeeds with matching term `t`. If `pred_fn` returns false
  then `p*` fails with an error message defined by `err_msg_fn.(t)`.

  Example: ensure a keyword is from a pre-approved list
  ```
    satisfy(
      keyword,
      fn t -> t in [:stop, :go] end,
      fn t -> "Keyword \#{t} must be one of :stop or :go" end
    )
  ```
  """

  @spec satisfy(Parser.combinator(), match_pred(), error_message_generator()) :: Parser.parser()

  def satisfy(p, pred, err_msg_fn \\ fn x -> x end)
      when is_function(p) and is_function(pred ) and is_function(err_msg_fn) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: %{term: term}} = new_ctx <- p.(ctx) do
        if pred.(term) do
          new_ctx
        else
          %{ctx | :status => :error, :message => err_msg_fn.(term)}
        end
      end
    end
  end

  @doc """
  `transform` is used to replace the matching term of a parser with a dynamic value based on the matching
  term. See also `replace`.

  `transform` accepts a parser `p` and a function `t` and returns a parser `p*` that accepts
  a `Epic.Context` `ctx`. `p*` calls `p.(ctx)`. If `p` succeeds with a matching term `t` then `p*` succeeds
  with a matching term defined by the result of `t.(t)`.

  Example: Convert a series of digits to a string
  ```
    many(digit()) |> transform(fn t -> List.to_string(t) end)
  ```
  """

  @spec transform(Parser.combinator(), transformer()) :: Parser.parser()

  def transform(p, t)
      when is_function(p) and is_function(t) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: %{term: term} = match} = new_ctx <- p.(ctx) do
        %{new_ctx | match: %{match | term: t.(term)}}
      end
    end
  end

  @doc """
  `replace` is used to replace the matching term of a parser with a pre-defined constant. See also
  `transform`.

  `replace` accepts a parser `p` and an opaque value `v` and returns a parser `p*` that accepts
  a `Epic.Context` `ctx`. `p*` calls `p.(ctx)`. If `p` succeeds then `p*` succeeds with a
  match term of `v`.

  Example: Replace matched char with keyword
  ```
    char(?+) |> replace(:+)
  ```
  """

  @spec replace(Parser.combinator(), any) :: Parser.parser()

  def replace(p, v) when is_function(p) do
    fn %Context{} = ctx ->
      with %Context{status: :ok, match: match} = new_ctx <- p.(ctx) do
        %{new_ctx | match: %{match | term: v}}
      end
    end
  end
end
