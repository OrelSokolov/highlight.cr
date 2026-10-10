# Порт lib/languages/csharp.js (highlight.js 11.12.0).

module Highlight::Languages
  module Csharp
    def self.defined(hljs : HLJS) : Mode
      built_in_keywords = [
        "bool",
        "byte",
        "char",
        "decimal",
        "delegate",
        "double",
        "dynamic",
        "enum",
        "float",
        "int",
        "long",
        "nint",
        "nuint",
        "object",
        "sbyte",
        "short",
        "string",
        "ulong",
        "uint",
        "ushort",
      ]
      function_modifiers = [
        "public",
        "private",
        "protected",
        "static",
        "internal",
        "protected",
        "abstract",
        "async",
        "extern",
        "override",
        "unsafe",
        "virtual",
        "new",
        "sealed",
        "partial",
      ]
      literal_keywords = [
        "default",
        "false",
        "null",
        "true",
      ]
      normal_keywords = [
        "abstract",
        "as",
        "base",
        "break",
        "case",
        "catch",
        "class",
        "const",
        "continue",
        "do",
        "else",
        "event",
        "explicit",
        "extern",
        "finally",
        "fixed",
        "for",
        "foreach",
        "goto",
        "if",
        "implicit",
        "in",
        "interface",
        "internal",
        "is",
        "lock",
        "namespace",
        "new",
        "operator",
        "out",
        "override",
        "params",
        "private",
        "protected",
        "public",
        "readonly",
        "record",
        "ref",
        "return",
        "scoped",
        "sealed",
        "sizeof",
        "stackalloc",
        "static",
        "struct",
        "switch",
        "this",
        "throw",
        "try",
        "typeof",
        "unchecked",
        "unsafe",
        "using",
        "virtual",
        "void",
        "volatile",
        "while",
      ]
      contextual_keywords = [
        "add",
        "alias",
        "and",
        "ascending",
        "args",
        "async",
        "await",
        "by",
        "descending",
        "dynamic",
        "equals",
        "file",
        "from",
        "get",
        "global",
        "group",
        "init",
        "into",
        "join",
        "let",
        "nameof",
        "not",
        "notnull",
        "on",
        "or",
        "orderby",
        "partial",
        "record",
        "remove",
        "required",
        "scoped",
        "select",
        "set",
        "unmanaged",
        "value|0",
        "var",
        "when",
        "where",
        "with",
        "yield",
      ]

      keywords = {} of String => KeywordsVal
      keywords["keyword"] = normal_keywords.concat(contextual_keywords)
      keywords["built_in"] = built_in_keywords
      keywords["literal"] = literal_keywords
      title_mode = MODES::TITLE_MODE.inherit(Mode.new.apply(begin: "[a-zA-Z](\\.?\\w)*"))
      # https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/integral-numeric-types
      # https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types
      # `_` separators sit between digits, and may also follow the `0x`/`0b` prefix
      digits = "\\d(_*\\d)*"
      integer_suffix = "([uU][lL]?|[lL][uU]?)?"
      real_suffix = "([fFdDmM]|[uU][lL]?|[lL][uU]?)?"
      numbers = Mode.new.apply(
        class_name: "number",
        variants: [
          Mode.new.apply(begin: "\\b0[bB]_*[01](_*[01])*" + integer_suffix),
          Mode.new.apply(begin: "(-?)\\b0[xX]_*[a-fA-F0-9](_*[a-fA-F0-9])*" + integer_suffix),
          Mode.new.apply(begin: "(-?)(\\b" + digits + "(\\.(" + digits + ")?)?|\\." + digits + ")([eE][-+]?" + digits + ")?" + real_suffix),
        ] of Mode,
        relevance: 0
      )
      raw_string = Mode.new.apply(
        class_name: "string",
        begin: /"""("*)(?!")(.|\n)*?"""\1/,
        relevance: 1
      )
      verbatim_string = Mode.new.apply(
        class_name: "string",
        begin: "@\"",
        end: "\"",
        contains: [Mode.new.apply(begin: "\"\"")] of Mode
      )
      verbatim_string_no_lf = verbatim_string.inherit(Mode.new.apply(illegal: /\n/))
      subst = Mode.new.apply(
        class_name: "subst",
        begin: /\{/,
        end: /\}/,
        keywords: keywords
      )
      subst_no_lf = subst.inherit(Mode.new.apply(illegal: /\n/))
      interpolated_string = Mode.new.apply(
        class_name: "string",
        begin: /\$"/,
        end: "\"",
        illegal: /\n/,
        contains: [
          Mode.new.apply(begin: /\{\{/),
          Mode.new.apply(begin: /\}\}/),
          MODES::BACKSLASH_ESCAPE,
          subst_no_lf,
        ] of Mode
      )
      interpolated_verbatim_string = Mode.new.apply(
        class_name: "string",
        begin: /\$@"/,
        end: "\"",
        contains: [
          Mode.new.apply(begin: /\{\{/),
          Mode.new.apply(begin: /\}\}/),
          Mode.new.apply(begin: "\"\""),
          subst,
        ] of Mode
      )
      interpolated_verbatim_string_no_lf = interpolated_verbatim_string.inherit(Mode.new.apply(
        illegal: /\n/,
        contains: [
          Mode.new.apply(begin: /\{\{/),
          Mode.new.apply(begin: /\}\}/),
          Mode.new.apply(begin: "\"\""),
          subst_no_lf,
        ] of Mode
      ))
      subst.contains = [
        interpolated_verbatim_string,
        interpolated_string,
        verbatim_string,
        MODES::APOS_STRING_MODE,
        MODES::QUOTE_STRING_MODE,
        numbers,
        MODES::C_BLOCK_COMMENT_MODE,
      ] of Mode
      subst_no_lf.contains = [
        interpolated_verbatim_string_no_lf,
        interpolated_string,
        verbatim_string_no_lf,
        MODES::APOS_STRING_MODE,
        MODES::QUOTE_STRING_MODE,
        numbers,
        MODES::C_BLOCK_COMMENT_MODE.inherit(Mode.new.apply(illegal: /\n/)),
      ] of Mode
      string_mode = Mode.new.apply(variants: [
        raw_string,
        interpolated_verbatim_string,
        interpolated_string,
        verbatim_string,
        MODES::APOS_STRING_MODE,
        MODES::QUOTE_STRING_MODE,
      ] of Mode)

      generic_modifier = Mode.new.apply(
        begin: "<",
        end: ">",
        contains: [
          Mode.new.apply(begin_keywords: "in out"),
          title_mode,
        ] of Mode
      )
      type_ident_re = IDENT_RE + "(<" + IDENT_RE + "(\\s*,\\s*" + IDENT_RE + ")*>)?(\\[\\])?"
      at_identifier = Mode.new.apply(
        # prevents expressions like `@class` from incorrect flagging
        # `class` as a keyword
        begin: "@" + IDENT_RE,
        relevance: 0
      )

      Mode.new.apply(
        name: "C#",
        aliases: [
          "cs",
          "c#",
        ],
        keywords: keywords,
        illegal: /::/,
        contains: [
          hljs.comment(
            "///",
            "$",
            Mode.new.apply(
              return_begin: true,
              contains: [
                Mode.new.apply(
                  class_name: "doctag",
                  variants: [
                    Mode.new.apply(
                      begin: "///",
                      relevance: 0
                    ),
                    Mode.new.apply(begin: "<!--|-->"),
                    Mode.new.apply(
                      begin: "</?",
                      end: ">"
                    ),
                  ] of Mode
                ),
              ] of Mode
            )
          ),
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
          Mode.new.apply(
            class_name: "meta",
            begin: "#",
            end: "$",
            keywords: {"keyword" => "if else elif endif define undef warning error line region endregion pragma checksum"} of String => KeywordsVal
          ),
          string_mode,
          numbers,
          Mode.new.apply(
            begin_keywords: "class interface",
            relevance: 0,
            end: /[{;=]/,
            illegal: /[^\s:,]/,
            contains: [
              Mode.new.apply(begin_keywords: "where class"),
              title_mode,
              generic_modifier,
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          Mode.new.apply(
            begin_keywords: "namespace",
            relevance: 0,
            end: /[{;=]/,
            illegal: /[^\s:]/,
            contains: [
              title_mode,
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          Mode.new.apply(
            begin_keywords: "record",
            relevance: 0,
            end: /[{;=]/,
            illegal: /[^\s:]/,
            contains: [
              title_mode,
              generic_modifier,
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          # [Attributes("")]
          Mode.new.apply(
            class_name: "meta",
            begin: "^\\s*\\[(?=[\\w])",
            exclude_begin: true,
            end: "\\]",
            exclude_end: true,
            contains: [
              Mode.new.apply(
                class_name: "string",
                begin: /"/,
                end: /"/
              ),
            ] of Mode
          ),
          # Expression keywords prevent 'keyword Name(...)' from being
          # recognized as a function definition
          Mode.new.apply(
            begin_keywords: "new return throw await else",
            relevance: 0
          ),
          Mode.new.apply(
            class_name: "function",
            begin: "(" + type_ident_re + "\\s+)+" + IDENT_RE + "\\s*(<[^=]+>\\s*)?\\(",
            return_begin: true,
            end: /\s*[{;=]/,
            exclude_end: true,
            keywords: keywords,
            contains: [
              # prevents these from being highlighted `title`
              Mode.new.apply(
                begin_keywords: function_modifiers.join(" "),
                relevance: 0
              ),
              Mode.new.apply(
                begin: IDENT_RE + "\\s*(<[^=]+>\\s*)?\\(",
                return_begin: true,
                contains: [
                  MODES::TITLE_MODE,
                  generic_modifier,
                ] of Mode,
                relevance: 0
              ),
              Mode.new.apply(match: /\(\)/),
              Mode.new.apply(
                class_name: "params",
                begin: /\(/,
                end: /\)/,
                exclude_begin: true,
                exclude_end: true,
                keywords: keywords,
                relevance: 0,
                contains: [
                  string_mode,
                  numbers,
                  MODES::C_BLOCK_COMMENT_MODE,
                ] of Mode
              ),
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          at_identifier,
        ] of Mode
      )
    end
  end

  Languages.register("csharp", ->(hljs : HLJS) { Csharp.defined(hljs) })
end
