# Порт lib/languages/graphql.js (highlight.js 11.12.0).

module Highlight::Languages
  module Graphql
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      gql_name = /[_A-Za-z][_0-9A-Za-z]*/
      keywords = {} of String => KeywordsVal
      keywords["keyword"] = [
        "query",
        "mutation",
        "subscription",
        "type",
        "input",
        "schema",
        "directive",
        "interface",
        "union",
        "scalar",
        "fragment",
        "enum",
        "on",
      ]
      keywords["literal"] = [
        "true",
        "false",
        "null",
      ]
      Mode.new.apply(
        name: "GraphQL",
        aliases: ["gql"],
        case_insensitive: true,
        disable_autodetect: false,
        keywords: keywords,
        contains: [
          MODES::HASH_COMMENT_MODE,
          MODES::QUOTE_STRING_MODE,
          MODES::NUMBER_MODE,
          Mode.new.apply(
            scope: "punctuation",
            match: /[.]{3}/,
            relevance: 0
          ),
          Mode.new.apply(
            scope: "punctuation",
            begin: /[\!\(\)\:\=\[\]\{\|\}]{1}/,
            relevance: 0
          ),
          Mode.new.apply(
            scope: "variable",
            begin: /\$/,
            end: /\W/,
            exclude_end: true,
            relevance: 0
          ),
          Mode.new.apply(
            scope: "meta",
            match: /@\w+/,
            exclude_end: true
          ),
          Mode.new.apply(
            scope: "symbol",
            begin: regex.concat(gql_name, regex.lookahead(/\s*:/)),
            relevance: 0
          ),
        ] of Mode,
        illegal: [
          %r([;<']),
          /BEGIN/,
        ] of String | Regex
      )
    end
  end

  Languages.register("graphql", ->(hljs : HLJS) { Graphql.defined(hljs) })
end
