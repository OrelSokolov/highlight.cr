# Порт lib/languages/java.js (highlight.js 11.12.0).

module Highlight::Languages
  module JavaLang
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

    # Allows recursive regex expressions to a given depth
    # ie: recurRegex("(abc~~~)", /~~~/g, 2) becomes: (abc(abc(abc)))
    private def self.recur_regex(re : String, substitution : String, depth : Int32) : String
      return "" if depth == -1
      re.gsub(substitution) { recur_regex(re, substitution, depth - 1) }
    end

    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      numeric = numeric_mode

      # A Java identifier consisting of letters, digits, underscore or dollar sign, not beginning with a digit
      java_ident_re = "[\u00C0-\u02B8a-zA-Z_$][\u00C0-\u02B8a-zA-Z_$0-9]*"

      # Optional 1..n pairs of square brackets identifying an array type
      array_brackets_optional_re = "(?:(?:\\s*\\[\\s*)+)?"

      # A simple Java type: a type name, optionally followed by type arguments and/or array brackets
      # '<@@@>' is replaced with the pattern for optional type arguments by recurRegex below.
      simple_type_re = java_ident_re + "<@@@>" + array_brackets_optional_re

      # A bounded (? extends Number) or unbounded (?) wildcard type
      wildcard_type_re = "\\?(?:\\s+(?:extends|super)\\s+" + simple_type_re + ")?"

      # A Java type argument, consisting of a wildcard or simple type
      type_arg_re = "(?:" + wildcard_type_re + "|" + simple_type_re + ")"

      # Pattern for optional generic type arguments in angle brackets with up to 2 levels of nested type arguments
      type_args_optional_re = recur_regex("(?:\\s*<\\s*" + type_arg_re + "(?:\\s*,\\s*" + type_arg_re + ")*\\s*>)?",
        "<@@@>", 2)

      main_keywords = [
        "synchronized",
        "abstract",
        "private",
        "var",
        "static",
        "if",
        "const ",
        "for",
        "while",
        "strictfp",
        "finally",
        "protected",
        "import",
        "native",
        "final",
        "void",
        "enum",
        "else",
        "break",
        "transient",
        "catch",
        "instanceof",
        "volatile",
        "case",
        "assert",
        "package",
        "default",
        "public",
        "try",
        "switch",
        "continue",
        "throws",
        "protected",
        "public",
        "private",
        "module",
        "requires",
        "exports",
        "do",
        "sealed",
        "yield",
        "permits",
        "goto",
        "when",
      ]

      built_ins = [
        "super",
        "this",
      ]

      literals = [
        "false",
        "true",
        "null",
      ]

      types = [
        "char",
        "boolean",
        "long",
        "float",
        "int",
        "byte",
        "short",
        "double",
      ]

      keywords = {} of String => KeywordsVal
      keywords["keyword"] = main_keywords
      keywords["literal"] = literals
      keywords["type"] = types
      keywords["built_in"] = built_ins

      annotation_mode = Mode.new.apply(
        class_name: "meta",
        begin: "@" + java_ident_re,
        contains: [
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            contains: [Mode.self_marker] of Mode # allow nested () inside our annotation
          ),
        ] of Mode
      )
      params = Mode.new.apply(
        class_name: "params",
        begin: /\(/,
        end: /\)/,
        keywords: keywords,
        relevance: 0,
        contains: [MODES::C_BLOCK_COMMENT_MODE] of Mode,
        ends_parent: true
      )

      Mode.new.apply(
        name: "Java",
        aliases: ["jsp"],
        keywords: keywords,
        illegal: /<\/|#/,
        contains: [
          hljs.comment(
            "/\\*\\*",
            "\\*/",
            Mode.new.apply(
              relevance: 0,
              contains: [
                # eat up @'s in emails to prevent them to be recognized as doctags
                Mode.new.apply(
                  begin: /\w+@/,
                  relevance: 0
                ),
                Mode.new.apply(
                  class_name: "doctag",
                  begin: "@[A-Za-z]+"
                ),
              ] of Mode
            )
          ),
          # relevance boost
          Mode.new.apply(
            begin: /import java\.[a-z]+\./,
            keywords: "import",
            relevance: 2
          ),
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
          Mode.new.apply(
            begin: /"""/,
            end: /"""/,
            class_name: "string",
            contains: [MODES::BACKSLASH_ESCAPE] of Mode
          ),
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
          Mode.new.apply(
            match: [
              /\b(?:class|interface|enum|extends|implements|new)/,
              /\s+/,
              java_ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
            }
          ),
          # Exceptions for hyphenated keywords
          Mode.new.apply(
            match: /non-sealed/,
            scope: "keyword"
          ),
          # Expression keywords prevent keyword-led expressions from being
          # recognized as variable or method declarations.
          Mode.new.apply(
            begin_keywords: "new throw return else yield assert",
            relevance: 0
          ),
          Mode.new.apply(
            begin: [
              java_ident_re,
              regex.concat(type_args_optional_re, array_brackets_optional_re, /\s+/),
              java_ident_re,
              array_brackets_optional_re,
              /\s*/,
              /=(?!=)/,
            ] of String | Regex,
            scope: {
              "1" => "type",
              "3" => "variable",
              "6" => "operator",
            }
          ),
          Mode.new.apply(
            begin: [
              /record/,
              /\s+/,
              java_ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
            },
            contains: [
              params,
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          Mode.new.apply(
            begin: [
              java_ident_re,
              regex.concat(type_args_optional_re, array_brackets_optional_re, /\s+/),
              java_ident_re,
              /\s*(?=\()/,
            ] of String | Regex,
            scope: {
              "1" => "type",
              "3" => "title.function",
            },
            keywords: keywords,
            contains: [
              Mode.new.apply(
                class_name: "params",
                begin: /\(/,
                end: /\)/,
                keywords: keywords,
                relevance: 0,
                contains: [
                  annotation_mode,
                  MODES::APOS_STRING_MODE,
                  MODES::QUOTE_STRING_MODE,
                  numeric,
                  MODES::C_BLOCK_COMMENT_MODE,
                ] of Mode
              ),
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          numeric,
          annotation_mode,
        ] of Mode
      )
    end
  end

  Languages.register("java", ->(hljs : HLJS) { JavaLang.defined(hljs) })
end
