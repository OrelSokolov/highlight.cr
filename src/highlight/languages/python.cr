# Порт lib/languages/python.js (highlight.js 11.12.0).

module Highlight::Languages
  module Python
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      ident_re = /[\p{XID_Start}_]\p{XID_Continue}*/
      reserved_words = [
        "and",
        "as",
        "assert",
        "async",
        "await",
        "break",
        "case",
        "class",
        "continue",
        "def",
        "del",
        "elif",
        "else",
        "except",
        "finally",
        "for",
        "from",
        "global",
        "if",
        "import",
        "in",
        "is",
        "lambda",
        "lazy",
        "match",
        "nonlocal|10",
        "not",
        "or",
        "pass",
        "raise",
        "return",
        "try",
        "while",
        "with",
        "yield",
      ]

      built_ins = [
        "__import__",
        "abs",
        "aiter",
        "all",
        "anext",
        "any",
        "ascii",
        "bin",
        "bool",
        "breakpoint",
        "bytearray",
        "bytes",
        "callable",
        "chr",
        "classmethod",
        "compile",
        "complex",
        "delattr",
        "dict",
        "dir",
        "divmod",
        "enumerate",
        "eval",
        "exec",
        "filter",
        "float",
        "format",
        "frozendict",
        "frozenset",
        "getattr",
        "globals",
        "hasattr",
        "hash",
        "help",
        "hex",
        "id",
        "input",
        "int",
        "isinstance",
        "issubclass",
        "iter",
        "len",
        "list",
        "locals",
        "map",
        "max",
        "memoryview",
        "min",
        "next",
        "object",
        "oct",
        "open",
        "ord",
        "pow",
        "print",
        "property",
        "range",
        "repr",
        "reversed",
        "round",
        "sentinel",
        "set",
        "setattr",
        "slice",
        "sorted",
        "staticmethod",
        "str",
        "sum",
        "super",
        "tuple",
        "type",
        "vars",
        "zip",
      ]

      literals = [
        "__debug__",
        "Ellipsis",
        "False",
        "None",
        "NotImplemented",
        "True",
      ]

      # https://docs.python.org/3/library/typing.html
      types = [
        "Any",
        "Callable",
        "Coroutine",
        "Dict",
        "List",
        "Literal",
        "Generic",
        "Optional",
        "Sequence",
        "Set",
        "Tuple",
        "Type",
        "Union",
      ]

      keywords = {} of String => KeywordsVal
      keywords["$pattern"] = "[A-Za-z]\\w+|__\\w+__"
      keywords["keyword"] = reserved_words
      keywords["built_in"] = built_ins
      keywords["literal"] = literals
      keywords["type"] = types

      prompt = Mode.new.apply(
        class_name: "meta",
        begin: /^(>>>|\.\.\.) /
      )

      subst = Mode.new.apply(
        class_name: "subst",
        begin: /\{/,
        end: /\}/,
        keywords: keywords,
        illegal: /#/
      )

      literal_bracket = Mode.new.apply(
        begin: /\{\{/,
        relevance: 0
      )

      string_mode = Mode.new.apply(
        class_name: "string",
        contains: [MODES::BACKSLASH_ESCAPE] of Mode,
        variants: [
          Mode.new.apply(
            begin: /([uU]|[bB]|[rR]|[bB][rR]|[rR][bB])?'''/,
            end: /'''/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              prompt,
            ] of Mode,
            relevance: 10
          ),
          Mode.new.apply(
            begin: /([uU]|[bB]|[rR]|[bB][rR]|[rR][bB])?"""/,
            end: /"""/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              prompt,
            ] of Mode,
            relevance: 10
          ),
          Mode.new.apply(
            begin: /([fFtT][rR]|[rR][fFtT]|[fFtT])'''/,
            end: /'''/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              prompt,
              literal_bracket,
              subst,
            ] of Mode
          ),
          Mode.new.apply(
            begin: /([fFtT][rR]|[rR][fFtT]|[fFtT])"""/,
            end: /"""/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              prompt,
              literal_bracket,
              subst,
            ] of Mode
          ),
          Mode.new.apply(
            begin: /([uU]|[rR])'/,
            end: /'/,
            relevance: 10
          ),
          Mode.new.apply(
            begin: /([uU]|[rR])"/,
            end: /"/,
            relevance: 10
          ),
          Mode.new.apply(
            begin: /([bB]|[bB][rR]|[rR][bB])'/,
            end: /'/
          ),
          Mode.new.apply(
            begin: /([bB]|[bB][rR]|[rR][bB])"/,
            end: /"/
          ),
          Mode.new.apply(
            begin: /([fFtT][rR]|[rR][fFtT]|[fFtT])'/,
            end: /'/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              literal_bracket,
              subst,
            ] of Mode
          ),
          Mode.new.apply(
            begin: /([fFtT][rR]|[rR][fFtT]|[fFtT])"/,
            end: /"/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              literal_bracket,
              subst,
            ] of Mode
          ),
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
        ] of Mode
      )

      # https://docs.python.org/3.9/reference/lexical_analysis.html#numeric-literals
      digitpart = "[0-9](_?[0-9])*"
      pointfloat = "(\\b(#{digitpart}))?\\.(#{digitpart})|\\b(#{digitpart})\\."
      # Whitespace after a number (or any lexical token) is needed only if its absence
      # would change the tokenization
      # https://docs.python.org/3.9/reference/lexical_analysis.html#whitespace-between-tokens
      # We deviate slightly, requiring a word boundary or a keyword
      # to avoid accidentally recognizing *prefixes* (e.g., `0` in `0x41` or `08` or `0__1`)
      lookahead = "\\b|" + reserved_words.join("|")
      number = Mode.new.apply(
        class_name: "number",
        relevance: 0,
        variants: [
          # exponentfloat, pointfloat
          # https://docs.python.org/3.9/reference/lexical_analysis.html#floating-point-literals
          # optionally imaginary
          # https://docs.python.org/3.9/reference/lexical_analysis.html#imaginary-literals
          # Note: no leading \b because floats can start with a decimal point
          # and we don't want to mishandle e.g. `fn(.5)`,
          # no trailing \b for pointfloat because it can end with a decimal point
          # and we don't want to mishandle e.g. `0..hex()`; this should be safe
          # because both MUST contain a decimal point and so cannot be confused with
          # the interior part of an identifier
          Mode.new.apply(
            begin: "(\\b(#{digitpart})|(#{pointfloat}))[eE][+-]?(#{digitpart})[jJ]?(?=#{lookahead})"
          ),
          Mode.new.apply(
            begin: "(#{pointfloat})[jJ]?"
          ),

          # decinteger, bininteger, octinteger, hexinteger
          # https://docs.python.org/3.9/reference/lexical_analysis.html#integer-literals
          # optionally "long" in Python 2
          # decinteger is optionally imaginary
          Mode.new.apply(
            begin: "\\b([1-9](_?[0-9])*|0+(_?0)*)[lLjJ]?(?=#{lookahead})"
          ),
          Mode.new.apply(
            begin: "\\b0[bB](_?[01])+[lL]?(?=#{lookahead})"
          ),
          Mode.new.apply(
            begin: "\\b0[oO](_?[0-7])+[lL]?(?=#{lookahead})"
          ),
          Mode.new.apply(
            begin: "\\b0[xX](_?[0-9a-fA-F])+[lL]?(?=#{lookahead})"
          ),

          # imagnumber (digitpart-based)
          Mode.new.apply(
            begin: "\\b(#{digitpart})[jJ](?=#{lookahead})"
          ),
        ] of Mode
      )
      comment_type = Mode.new.apply(
        class_name: "comment",
        begin: regex.lookahead(/# type:/),
        end: /$/,
        keywords: keywords,
        contains: [
          # prevent keywords from coloring `type`
          Mode.new.apply(begin: /# type:/),
          # comment within a datatype comment includes no keywords
          Mode.new.apply(
            begin: /#/,
            end: /\b\B/,
            ends_with_parent: true
          ),
        ] of Mode
      )
      params = Mode.new.apply(
        class_name: "params",
        variants: [
          # Exclude params in functions without params
          Mode.new.apply(
            class_name: "",
            begin: /\(\s*\)/,
            skip: true
          ),
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            exclude_begin: true,
            exclude_end: true,
            keywords: keywords,
            contains: [
              Mode.self_marker,
              prompt,
              number,
              string_mode,
              MODES::HASH_COMMENT_MODE,
            ] of Mode
          ),
        ] of Mode
      )
      subst.contains = [
        string_mode,
        number,
        prompt,
      ] of Mode

      Mode.new.apply(
        name: "Python",
        aliases: [
          "py",
          "gyp",
          "ipython",
        ],
        unicode_regex: true,
        keywords: keywords,
        illegal: /(<\/|\?)|=>/,
        contains: [
          prompt,
          number,
          # very common convention
          Mode.new.apply(
            scope: "variable.language",
            match: /\bself\b/
          ),
          # eat "if" prior to string so that it won't accidentally be
          # labeled as an f-string
          Mode.new.apply(
            begin_keywords: "if",
            relevance: 0
          ),
          Mode.new.apply(match: /\bor\b/, scope: "keyword"),
          string_mode,
          comment_type,
          MODES::HASH_COMMENT_MODE,
          Mode.new.apply(
            match: [
              /\bdef/, /\s+/,
              ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.function",
            },
            contains: [params] of Mode
          ),
          Mode.new.apply(
            variants: [
              Mode.new.apply(
                match: [
                  /\bclass/, /\s+/,
                  ident_re, /\s*/,
                  /\(\s*/, ident_re, /\s*\)/,
                ] of String | Regex,
              ),
              Mode.new.apply(
                match: [
                  /\bclass/, /\s+/,
                  ident_re,
                ] of String | Regex,
              ),
            ] of Mode,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
              "6" => "title.class.inherited",
            }
          ),
          Mode.new.apply(
            class_name: "meta",
            begin: /^[\t ]*@/,
            end: /(?=#)|$/,
            contains: [
              number,
              params,
              string_mode,
            ] of Mode
          ),
        ] of Mode
      )
    end
  end

  Languages.register("python", ->(hljs : HLJS) { Python.defined(hljs) })
end
