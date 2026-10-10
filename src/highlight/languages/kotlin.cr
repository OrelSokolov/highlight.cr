# Порт lib/languages/kotlin.js (highlight.js 11.12.0).
# Числовой режим совпадает с java.js (документация Kotlin).

module Highlight::Languages
  module Kotlin
    # https://docs.oracle.com/javase/specs/jls/se15/html/jls-3.html#jls-3.10
    private def self.numeric_mode : Mode
      decimal_digits = "[0-9](_*[0-9])*"
      frac = "\\.(#{decimal_digits})"
      hex_digits = "[0-9a-fA-F](_*[0-9a-fA-F])*"
      Mode.new.apply(
        class_name: "number",
        variants: [
          # DecimalFloatingPointLiteral
          # including ExponentPart
          Mode.new.apply(begin: "(\\b(#{decimal_digits})((#{frac})|\\.)?|(#{frac}))" +
                                "[eE][+-]?(#{decimal_digits})[fFdD]?\\b"),
          # excluding ExponentPart
          Mode.new.apply(begin: "\\b(#{decimal_digits})((#{frac})[fFdD]?\\b|\\.([fFdD]\\b)?)"),
          Mode.new.apply(begin: "(#{frac})[fFdD]?\\b"),
          Mode.new.apply(begin: "\\b(#{decimal_digits})[fFdD]\\b"),

          # HexadecimalFloatingPointLiteral
          Mode.new.apply(begin: "\\b0[xX]((#{hex_digits})\\.?|(#{hex_digits})?\\.(#{hex_digits}))" +
                                "[pP][+-]?(#{decimal_digits})[fFdD]?\\b"),

          # DecimalIntegerLiteral
          Mode.new.apply(begin: "\\b(0|[1-9](_*[0-9])*)[lL]?\\b"),

          # HexIntegerLiteral
          Mode.new.apply(begin: "\\b0[xX](#{hex_digits})[lL]?\\b"),

          # OctalIntegerLiteral
          Mode.new.apply(begin: "\\b0(_*[0-7])*[lL]?\\b"),

          # BinaryIntegerLiteral
          Mode.new.apply(begin: "\\b0[bB][01](_*[01])*[lL]?\\b"),
        ] of Mode,
        relevance: 0
      )
    end

    def self.defined(hljs : HLJS) : Mode
      keywords = {
        "keyword" =>
          "abstract as val var vararg get set class object open private protected public noinline " +
          "crossinline dynamic final enum if else do while for when throw try catch finally " +
          "import package is in fun override companion reified inline lateinit init " +
          "interface annotation data sealed internal infix operator out by constructor super " +
          "tailrec where const inner suspend typealias external expect actual",
        "built_in" =>
          "Byte Short Char Int Long Boolean Float Double Void Unit Nothing",
        "literal" =>
          "true false null",
      } of String => KeywordsVal
      keywords_with_label = Mode.new.apply(
        class_name: "keyword",
        begin: /\b(break|continue|return|this)\b/,
        starts: Mode.new.apply(contains: [
          Mode.new.apply(
            class_name: "symbol",
            begin: /@\w+/
          ),
        ] of Mode)
      )
      label = Mode.new.apply(
        class_name: "symbol",
        begin: UNDERSCORE_IDENT_RE + "@"
      )

      # for string templates
      subst = Mode.new.apply(
        class_name: "subst",
        begin: /\$\{/,
        end: /\}/,
        contains: [MODES::C_NUMBER_MODE] of Mode
      )
      variable = Mode.new.apply(
        class_name: "variable",
        begin: "\\$" + UNDERSCORE_IDENT_RE
      )
      string_mode = Mode.new.apply(
        class_name: "string",
        variants: [
          Mode.new.apply(
            begin: "\"\"\"",
            end: "\"\"\"(?=[^\"])",
            contains: [
              variable,
              subst,
            ] of Mode
          ),
          # Can't use built-in modes easily, as we want to use STRING in the meta
          # context as 'meta-string' and there's no syntax to remove explicitly set
          # classNames in built-in modes.
          Mode.new.apply(
            begin: "'",
            end: "'",
            illegal: /\n/,
            contains: [MODES::BACKSLASH_ESCAPE] of Mode
          ),
          Mode.new.apply(
            begin: "\"",
            end: "\"",
            illegal: /\n/,
            contains: [
              MODES::BACKSLASH_ESCAPE,
              variable,
              subst,
            ] of Mode
          ),
        ] of Mode
      )
      subst.contains.not_nil! << string_mode

      annotation_use_site = Mode.new.apply(
        class_name: "meta",
        begin: "@(?:file|property|field|get|set|receiver|param|setparam|delegate)\\s*:(?:\\s*" + UNDERSCORE_IDENT_RE + ")?"
      )
      annotation_mode = Mode.new.apply(
        class_name: "meta",
        begin: "@" + UNDERSCORE_IDENT_RE,
        contains: [
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            contains: [
              # NB: annotate зарезервировано в Crystal
              string_mode.inherit(Mode.new.apply(class_name: "string")),
              Mode.self_marker,
            ] of Mode
          ),
        ] of Mode
      )

      # https://kotlinlang.org/docs/reference/whatsnew11.html#underscores-in-numeric-literals
      # According to the doc above, the number mode of kotlin is the same as java 8,
      # so the code below is copied from java.js
      kotlin_number_mode = numeric_mode
      kotlin_nested_comment = hljs.comment(
        "/\\*",
        "\\*/",
        Mode.new.apply(contains: [MODES::C_BLOCK_COMMENT_MODE] of Mode)
      )
      kotlin_paren_type = Mode.new.apply(variants: [
        Mode.new.apply(
          class_name: "type",
          begin: UNDERSCORE_IDENT_RE
        ),
        Mode.new.apply(
          begin: /\(/,
          end: /\)/,
          contains: [] of Mode # defined later
        ),
      ] of Mode)
      kotlin_paren_type2 = kotlin_paren_type
      kotlin_paren_type2.variants.not_nil![1].contains = [kotlin_paren_type] of Mode
      kotlin_paren_type.variants.not_nil![1].contains = [kotlin_paren_type2] of Mode

      Mode.new.apply(
        name: "Kotlin",
        aliases: [
          "kt",
          "kts",
          "ktm",
          "ktx",
        ],
        keywords: keywords,
        contains: [
          hljs.comment(
            "/\\*\\*",
            "\\*/",
            Mode.new.apply(
              relevance: 0,
              contains: [
                Mode.new.apply(
                  class_name: "doctag",
                  begin: "@[A-Za-z]+"
                ),
              ] of Mode
            )
          ),
          MODES::C_LINE_COMMENT_MODE,
          kotlin_nested_comment,
          keywords_with_label,
          label,
          annotation_use_site,
          annotation_mode,
          Mode.new.apply(
            class_name: "function",
            begin_keywords: "fun",
            end: "[(]|$",
            return_begin: true,
            exclude_end: true,
            keywords: keywords,
            relevance: 5,
            contains: [
              Mode.new.apply(
                begin: UNDERSCORE_IDENT_RE + "\\s*\\(",
                return_begin: true,
                relevance: 0,
                contains: [MODES::UNDERSCORE_TITLE_MODE] of Mode
              ),
              Mode.new.apply(
                class_name: "type",
                begin: /</,
                end: />/,
                keywords: "reified",
                relevance: 0
              ),
              Mode.new.apply(
                class_name: "params",
                begin: /\(/,
                end: /\)/,
                ends_parent: true,
                keywords: keywords,
                relevance: 0,
                contains: [
                  Mode.new.apply(
                    begin: /:/,
                    end: %r([=,/]),
                    ends_with_parent: true,
                    contains: [
                      kotlin_paren_type,
                      MODES::C_LINE_COMMENT_MODE,
                      kotlin_nested_comment,
                    ] of Mode,
                    relevance: 0
                  ),
                  MODES::C_LINE_COMMENT_MODE,
                  kotlin_nested_comment,
                  annotation_use_site,
                  annotation_mode,
                  string_mode,
                  MODES::C_NUMBER_MODE,
                ] of Mode
              ),
              kotlin_nested_comment,
            ] of Mode
          ),
          Mode.new.apply(
            begin: [
              /class|interface|trait/,
              /\s+/,
              UNDERSCORE_IDENT_RE,
            ] of String | Regex,
            begin_scope: {
              "3" => "title.class",
            },
            keywords: "class interface trait",
            end: /[:\{(]|$/,
            exclude_end: true,
            illegal: "extends implements",
            contains: [
              Mode.new.apply(begin_keywords: "public protected internal private constructor"),
              MODES::UNDERSCORE_TITLE_MODE,
              Mode.new.apply(
                class_name: "type",
                begin: /</,
                end: />/,
                exclude_begin: true,
                exclude_end: true,
                relevance: 0
              ),
              Mode.new.apply(
                class_name: "type",
                begin: /[,:]\s*/,
                end: /[<\(,){\s]|$/,
                exclude_begin: true,
                return_end: true
              ),
              annotation_use_site,
              annotation_mode,
            ] of Mode
          ),
          string_mode,
          Mode.new.apply(
            class_name: "meta",
            begin: "^#!/usr/bin/env",
            end: "$",
            illegal: "\n"
          ),
          kotlin_number_mode,
        ] of Mode
      )
    end
  end

  Languages.register("kotlin", ->(hljs : HLJS) { Kotlin.defined(hljs) })
end
