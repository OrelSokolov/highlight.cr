# Порт lib/languages/rust.js (highlight.js 11.12.0).

module Highlight::Languages
  module Rust
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # ============================================
      # Added to support the r# keyword, which is a raw identifier in Rust.
      raw_identifier = /(r#)?/
      underscore_ident_re = regex.concat(raw_identifier, UNDERSCORE_IDENT_RE)
      ident_re = regex.concat(raw_identifier, IDENT_RE)
      # ============================================
      function_invoke = Mode.new.apply(
        scope: "title.function.invoke",
        relevance: 0,
        begin: regex.concat(
          /\b/,
          /(?!(?:let|for|while|if|else|match)\b)/,
          ident_re,
          regex.lookahead(/\s*\(/))
      )
      # JS-строка '...\?' даёт просто '?' (неопознанный escape): суффикс опционален
      number_suffix = "([ui](8|16|32|64|128|size)|f(16|32|64|128))?"
      keywords = [
        "abstract",
        "as",
        "async",
        "await",
        "become",
        "box",
        "break",
        "const",
        "continue",
        "crate",
        "do",
        "dyn",
        "else",
        "enum",
        "extern",
        "false",
        "final",
        "fn",
        "for",
        "if",
        "impl",
        "in",
        "let",
        "loop",
        "macro",
        "match",
        "mod",
        "move",
        "mut",
        "override",
        "priv",
        "pub",
        "raw",
        "ref",
        "return",
        "self",
        "Self",
        "static",
        "struct",
        "super",
        "trait",
        "true",
        "try",
        "type",
        "typeof",
        "union",
        "unsafe",
        "unsized",
        "use",
        "virtual",
        "where",
        "while",
        "yield",
      ]
      literals = [
        "true",
        "false",
        "Some",
        "None",
        "Ok",
        "Err",
      ]
      builtins = [
        # functions
        "drop ",
        # traits
        "Copy",
        "Send",
        "Sized",
        "Sync",
        "Drop",
        "Fn",
        "FnMut",
        "FnOnce",
        "ToOwned",
        "Clone",
        "Debug",
        "PartialEq",
        "PartialOrd",
        "Eq",
        "Ord",
        "AsRef",
        "AsMut",
        "Into",
        "From",
        "Default",
        "Iterator",
        "Extend",
        "IntoIterator",
        "DoubleEndedIterator",
        "ExactSizeIterator",
        "SliceConcatExt",
        "ToString",
        # macros
        "assert!",
        "assert_eq!",
        "bitflags!",
        "bytes!",
        "cfg!",
        "col!",
        "concat!",
        "concat_idents!",
        "debug_assert!",
        "debug_assert_eq!",
        "env!",
        "eprintln!",
        "panic!",
        "file!",
        "format!",
        "format_args!",
        "include_bytes!",
        "include_str!",
        "line!",
        "local_data_key!",
        "module_path!",
        "option_env!",
        "print!",
        "println!",
        "select!",
        "stringify!",
        "try!",
        "unimplemented!",
        "unreachable!",
        "vec!",
        "write!",
        "writeln!",
        "macro_rules!",
        "assert_ne!",
        "debug_assert_ne!",
      ]
      types = [
        "i8",
        "i16",
        "i32",
        "i64",
        "i128",
        "isize",
        "u8",
        "u16",
        "u32",
        "u64",
        "u128",
        "usize",
        "f16",
        "f32",
        "f64",
        "f128",
        "str",
        "char",
        "bool",
        "Box",
        "Option",
        "Result",
        "String",
        "Vec",
      ]

      b_string = MODES::QUOTE_STRING_MODE.inherit(Mode.new.apply(begin: /b?"/))
      b_string.illegal = nil

      Mode.new.apply(
        name: "Rust",
        aliases: ["rs"],
        keywords: {
          "$pattern" => IDENT_RE + "!?",
          "type"     => types,
          "keyword"  => keywords,
          "literal"  => literals,
          "built_in" => builtins,
        } of String => KeywordsVal,
        illegal: "</",
        contains: [
          MODES::C_LINE_COMMENT_MODE,
          hljs.comment("/\\*", "\\*/", Mode.new.apply(contains: [Mode.self_marker] of Mode)),
          b_string,
          Mode.new.apply(
            scope: "symbol",
            # negative lookahead to avoid matching `'`
            begin: /'[a-zA-Z_][a-zA-Z0-9_]*(?!')/
          ),
          Mode.new.apply(
            scope: "string",
            variants: [
              Mode.new.apply(begin: /b?r(#*)"(.|\n)*?"\1(?!#)/),
              Mode.new.apply(
                begin: /b?'/,
                end: /'/,
                contains: [
                  Mode.new.apply(
                    scope: "char.escape",
                    match: /\\('|"|\\|\w|x\w{2}|u\w{4}|U\w{8})/
                  ),
                ] of Mode
              ),
            ] of Mode
          ),
          Mode.new.apply(
            scope: "number",
            variants: [
              Mode.new.apply(begin: "\\b0b([01_]+)" + number_suffix),
              Mode.new.apply(begin: "\\b0o([0-7_]+)" + number_suffix),
              Mode.new.apply(begin: "\\b0x([A-Fa-f0-9_]+)" + number_suffix),
              Mode.new.apply(begin: "\\b(\\d[\\d_]*(\\.[0-9_]+)?([eE][+-]?[0-9_]+)?)" + number_suffix),
            ] of Mode,
            relevance: 0
          ),
          Mode.new.apply(
            begin: [
              /\bsafe/,
              /\s+/,
              /extern/,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "keyword",
            }
          ),
          Mode.new.apply(
            begin: [
              /fn/,
              /\s+/,
              underscore_ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.function",
            }
          ),
          Mode.new.apply(
            scope: "meta",
            begin: "#!?\\[",
            end: "\\]",
            contains: [
              Mode.new.apply(
                scope: "string",
                begin: /"/,
                end: /"/,
                contains: [
                  MODES::BACKSLASH_ESCAPE,
                ] of Mode
              ),
            ] of Mode
          ),
          Mode.new.apply(
            begin: [
              /let/,
              /\s+/,
              /(?:mut\s+)?/,
              underscore_ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "keyword",
              "4" => "variable",
            }
          ),
          # must come before impl/for rule later
          Mode.new.apply(
            begin: [
              /for/,
              /\s+/,
              underscore_ident_re,
              /\s+/,
              /in/,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "variable",
              "5" => "keyword",
            }
          ),
          Mode.new.apply(
            begin: [
              /type/,
              /\s+/,
              underscore_ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
            }
          ),
          Mode.new.apply(
            begin: [
              /(?:trait|enum|struct|union|impl|for)/,
              /\s+/,
              underscore_ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
            }
          ),
          Mode.new.apply(
            begin: IDENT_RE + "::",
            keywords: {
              "keyword"  => "Self",
              "built_in" => builtins,
              "type"     => types,
            } of String => KeywordsVal
          ),
          Mode.new.apply(
            scope: "punctuation",
            begin: "->"
          ),
          function_invoke,
        ] of Mode
      )
    end
  end

  Languages.register("rust", ->(hljs : HLJS) { Rust.defined(hljs) })
end
