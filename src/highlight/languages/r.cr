# Порт lib/languages/r.js (highlight.js 11.12.0).

module Highlight::Languages
  module RLang
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # Identifiers in R cannot start with `_`, but they can start with `.` if it
      # is not immediately followed by a digit.
      # R also supports quoted identifiers, which are near-arbitrary sequences
      # delimited by backticks (`…`), which may contain escape sequences. These are
      # handled in a separate mode. See `test/markup/r/names.txt` for examples.
      # FIXME: Support Unicode identifiers.
      ident_re = /(?:(?:[a-zA-Z]|\.[._a-zA-Z])[._a-zA-Z0-9]*)|\.(?!\d)/
      number_types_re = regex.either([
        # Special case: only hexadecimal binary powers can contain fractions
        /0[xX][0-9a-fA-F]+\.[0-9a-fA-F]*[pP][+-]?\d+i?/,
        # Hexadecimal numbers without fraction and optional binary power
        /0[xX][0-9a-fA-F]+(?:[pP][+-]?\d+)?[Li]?/,
        # Decimal numbers
        /(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?[Li]?/,
      ])
      operators_re = /[=!<>:]=|\|\||&&|:::?|<-|<<-|->>|->|\|>|[-+*\/?!$&|:<=>@^~]|\*\*/
      punctuation_re = regex.either([
        /[()]/,
        /[{}]/,
        /\[\[/,
        /[[\]]/,
        /\\/,
        /,/,
      ])

      keywords = {} of String => KeywordsVal
      keywords["$pattern"] = ident_re.source
      keywords["keyword"] = "function if in break next repeat else for while"
      keywords["literal"] =
        "NULL NA TRUE FALSE Inf NaN NA_integer_|10 NA_real_|10 " +
        "NA_character_|10 NA_complex_|10"
      keywords["built_in"] =
        # Builtin constants
        "LETTERS letters month.abb month.name pi T F " +
        # Primitive functions
        # These are all the functions in `base` that are implemented as a
        # `.Primitive`, minus those functions that are also keywords.
        "abs acos acosh all any anyNA Arg as.call as.character " +
        "as.complex as.double as.environment as.integer as.logical " +
        "as.null.default as.numeric as.raw asin asinh atan atanh attr " +
        "attributes baseenv browser c call ceiling class Conj cos cosh " +
        "cospi cummax cummin cumprod cumsum digamma dim dimnames " +
        "emptyenv exp expression floor forceAndCall gamma gc.time " +
        "globalenv Im interactive invisible is.array is.atomic is.call " +
        "is.character is.complex is.double is.environment is.expression " +
        "is.finite is.function is.infinite is.integer is.language " +
        "is.list is.logical is.matrix is.na is.name is.nan is.null " +
        "is.numeric is.object is.pairlist is.raw is.recursive is.single " +
        "is.symbol lazyLoadDBfetch length lgamma list log max min " +
        "missing Mod names nargs nzchar oldClass on.exit pos.to.env " +
        "proc.time prod quote range Re rep retracemem return round " +
        "seq_along seq_len seq.int sign signif sin sinh sinpi sqrt " +
        "standardGeneric substitute sum switch tan tanh tanpi tracemem " +
        "trigamma trunc unclass untracemem UseMethod xtfrm"

      Mode.new.apply(
        name: "R",
        keywords: keywords,
        contains: [
          # Roxygen comments
          hljs.comment(
            /#'/,
            /$/,
            Mode.new.apply(contains: [
              # Handle `@examples` separately to cause all subsequent code
              # until the next `@`-tag on its own line to be kept as-is,
              # preventing highlighting. This code is example R code, so nested
              # doctags shouldn’t be treated as such. See
              # `test/markup/r/roxygen.txt` for an example.
              Mode.new.apply(
                scope: "doctag",
                match: /@examples/,
                starts: Mode.new.apply(
                  end: regex.lookahead(regex.either([
                    # end if another doc comment
                    /\n^#'\s*(?=@[a-zA-Z]+)/,
                    # or a line with no comment
                    /\n^(?!#')/,
                  ])),
                  ends_parent: true
                )
              ),
              # Handle `@param` to highlight the parameter name following
              # after.
              Mode.new.apply(
                scope: "doctag",
                begin: "@param",
                end: /$/,
                contains: [
                  Mode.new.apply(
                    scope: "variable",
                    variants: [
                      Mode.new.apply(match: ident_re),
                      Mode.new.apply(match: /`(?:\\.|[^`\\])+`/),
                    ] of Mode,
                    ends_parent: true
                  ),
                ] of Mode
              ),
              Mode.new.apply(
                scope: "doctag",
                match: /@[a-zA-Z]+/
              ),
              Mode.new.apply(
                scope: "keyword",
                match: /\\[a-zA-Z]+/
              ),
            ] of Mode)
          ),

          MODES::HASH_COMMENT_MODE,

          Mode.new.apply(
            scope: "string",
            contains: [MODES::BACKSLASH_ESCAPE] of Mode,
            variants: [
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /[rR]"(-*)\(/,
                end: /\)(-*)"/
              )),
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /[rR]"(-*)\{/,
                end: /\}(-*)"/
              )),
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /[rR]"(-*)\[/,
                end: /\](-*)"/
              )),
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /[rR]'(-*)\(/,
                end: /\)(-*)'/
              )),
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /[rR]'(-*)\{/,
                end: /\}(-*)'/
              )),
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /[rR]'(-*)\[/,
                end: /\](-*)'/
              )),
              Mode.new.apply(
                begin: "\"",
                end: "\"",
                relevance: 0
              ),
              Mode.new.apply(
                begin: "'",
                end: "'",
                relevance: 0
              ),
            ] of Mode
          ),

          # Matching numbers immediately following punctuation and operators is
          # tricky since we need to look at the character ahead of a number to
          # ensure the number is not part of an identifier, and we cannot use
          # negative look-behind assertions. So instead we explicitly handle all
          # possible combinations of (operator|punctuation), number.
          # TODO: replace with negative look-behind when available
          Mode.new.apply(
            relevance: 0,
            variants: [
              Mode.new.apply(
                scope: {"1" => "operator", "2" => "number"},
                match: [
                  operators_re,
                  number_types_re,
                ] of String | Regex
              ),
              Mode.new.apply(
                scope: {"1" => "operator", "2" => "number"},
                match: [
                  /%[^%]*%/,
                  number_types_re,
                ] of String | Regex
              ),
              Mode.new.apply(
                scope: {"1" => "punctuation", "2" => "number"},
                match: [
                  punctuation_re,
                  number_types_re,
                ] of String | Regex
              ),
              Mode.new.apply(
                scope: {"2" => "number"},
                match: [
                  /[^a-zA-Z0-9._]|^/, # not part of an identifier, or start of document
                  number_types_re,
                ] of String | Regex
              ),
            ] of Mode
          ),

          # Operators/punctuation when they're not directly followed by numbers
          Mode.new.apply(
            # Relevance boost for the most common assignment form.
            scope: {"3" => "operator"},
            match: [
              ident_re,
              /\s+/,
              /<-/,
              /\s+/,
            ] of String | Regex
          ),

          Mode.new.apply(
            scope: "operator",
            relevance: 0,
            variants: [
              Mode.new.apply(match: operators_re),
              Mode.new.apply(match: /%[^%]*%/),
            ] of Mode
          ),

          Mode.new.apply(
            scope: "punctuation",
            relevance: 0,
            match: punctuation_re
          ),

          Mode.new.apply(
            # Escaped identifier
            begin: "`",
            end: "`",
            contains: [Mode.new.apply(begin: /\\./)] of Mode
          ),
        ] of Mode
      )
    end
  end

  Languages.register("r", ->(hljs : HLJS) { RLang.defined(hljs) })
end
