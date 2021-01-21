# Epic

Author: Matt Mower <matt@theartofnavigation.co.uk>

## Introduction

Epic is a Parser Combinator library. That is, it is a library that you can use to build
a parser assembled out of smaller parsers. For example if you wanted to parse expressions
like:

    1+2
    3*4
    5/6
    7-8

you might imagine building a combinator parser like

    integer() |> operator() |> integer()

where `integer` is a parser responsible for parsing digitals and `operator` is a parser
responsible for parsing symbols like `+` and `*`.

For such a simple input grammar you might reach for a regular expression and that would be quite a reasonable choice. However, as the complexity of the inputs increases, regular expressions become less easy to understand and maintain.

For example to parse an input such as:

    Game {
      @title = "See the galaxy on less than five Altarian dollars a day"
      @author = "Matt Mower"
      @author_email = "matt@theartofnavigation.co.uk"
      @uuid = "FCCBAE02-3FD5-45C4-A56B-ECEA30B31610"

      Act earth_destroyed {
        @title = "The first act"
        @protagonist = #arthur_dent
        @antagonists = [#ford_prefect, #mr_prosser, #vogon_captain]

        Scene yellow_bulldozer {
          @opening_dialogue = #ford_prefect "Hello Arthur"
          …
        }
      }

      Act earth_mark_two {
        …
      }
    }

    and so on…

with regular expressions would be unnecessarily complex and difficult. At this point you need a parser.

Parser combinators, like Epic, allow for the "layering up" of simple parsers into more complex parsers. This
helps to clarify intent. As well it makes it easy to transform parsed terms into more useful forms. An imagined
form of parser combinator for the above input (ignoring whitespace issues) might look like:

    game =
      string("Game")
      |> string("{"})
      |> many(choice([attribute,act]))
      |> string("}")

    act =
      string("Act")
      |> id
      |> string("{")
      |> many(choice([attribute,scene]))
      |> string("}")

    attribute =
      string("@")
      |> identifier
      |> string("=")
      |> value

    and so on…

Epic provides a number of helpful low-level parsers like `string`, `many`, and `choice` which can be combined, DSL like, to form a more complex parser for your input grammar. Additionally it provides useful transformers
that can convert parsed results into maps and records.

Lastly, because Epic was created to parse a human authored format, some effort has been made to ensure that
Epic parsers can be made to report human readbale error messages with useful positional information.

## Background

I wanted a parser for a moderately complicated text format. I came across [NimbleParsec](https://github.com/dashbitco/nimble_parsec) which is a parser combinator library by the author of Elixir, José Valim.

NimbleParsec is pretty easy to get started with and, by all accounts, blazingly fast because José knows all
the right tricks. Unfortunately when it came to error handling I couldn't find any [good examples or guidance](https://elixirforum.com/t/can-you-help-me-understand-how-to-implement-nimbleparsec-error-handling/36637). If
your context is consuming largely machine-generated inputs where performance outweighs quality of error reporting I think this would be a great choice. For example, if I were writing an HTTP protocol parser I'd use NimbleParsec.

Saša Jurić sent me a link to a video where he [builds up parser combinators from the ground up](https://www.youtube.com/watch?v=xNzoerDljjo). This helped solidify my understanding of the parser combinator approach and
I realised I could build my own library and try to focus on those areas where I was struggling to make NimbleParsec work for me.

Hence Epic was born.

The first decision I made was to use a `Context` record to maintain the parser state and have all parsers
consume and return contexts. The context includes the parser input. I also introduced `Position` to manage
positional information and `Match` to manage the terms being matched, including storing the match position
separately from the parser position.

I do not recommend using this library as it is probably incomplete and may not work in
all cases and it's raison d'etre (better error handling) is still a matter of conjecture. However,
if you want to learn about parser combinators and follow-along I suspect my code will be much
easier to understand and reason about than the NimbleParsec source.

If you are more interested in performance than error handling then NimbleParsec is the best game in town
as of the the time of writing.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `epic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:epic, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/epic](https://hexdocs.pm/epic).
