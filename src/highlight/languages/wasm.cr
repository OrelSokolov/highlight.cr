# Порт lib/languages/wasm.js (highlight.js 11.12.0).

module Highlight::Languages
  module Wasm
    def self.defined(hljs : HLJS) : Mode
      block_comment = hljs.comment(/\(;/, /;\)/)
      block_comment.contains.not_nil! << Mode.self_marker
      line_comment = hljs.comment(/;;/, /$/)

      kws = [
        "anyfunc",
        "block",
        "br",
        "br_if",
        "br_table",
        "call",
        "call_indirect",
        "data",
        "drop",
        "elem",
        "else",
        "end",
        "export",
        "func",
        "global.get",
        "global.set",
        "local.get",
        "local.set",
        "local.tee",
        "get_global",
        "get_local",
        "global",
        "if",
        "import",
        "local",
        "loop",
        "memory",
        "memory.grow",
        "memory.size",
        "module",
        "mut",
        "nop",
        "offset",
        "param",
        "result",
        "return",
        "select",
        "set_global",
        "set_local",
        "start",
        "table",
        "tee_local",
        "then",
        "type",
        "unreachable",
      ]

      function_reference = Mode.new.apply(
        begin: [
          /(?:func|call|call_indirect)/,
          /\s+/,
          /\$[^\s)]+/,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "title.function",
        }
      )

      argument = Mode.new.apply(
        class_name: "variable",
        begin: /\$[\w_]+/
      )

      parens = Mode.new.apply(
        match: /(\((?!;)|\))+/,
        class_name: "punctuation",
        relevance: 0
      )

      number = Mode.new.apply(
        class_name: "number",
        relevance: 0,
        # borrowed from Prism, TODO: split out into variants
        match: /[+-]?\b(?:\d(?:_?\d)*(?:\.\d(?:_?\d)*)?(?:[eE][+-]?\d(?:_?\d)*)?|0x[\da-fA-F](?:_?[\da-fA-F])*(?:\.[\da-fA-F](?:_?[\da-fA-D])*)?(?:[pP][+-]?\d(?:_?\d)*)?)\b|\binf\b|\bnan(?::0x[\da-fA-F](?:_?[\da-fA-D])*)?\b/
      )

      type_mode = Mode.new.apply(
        # look-ahead prevents us from gobbling up opcodes
        match: /(i32|i64|f32|f64)(?!\.)/,
        class_name: "type"
      )

      math_operations = Mode.new.apply(
        class_name: "keyword",
        # borrowed from Prism, TODO: split out into variants
        match: /\b(f32|f64|i32|i64)(?:\.(?:abs|add|and|ceil|clz|const|convert_[su]\/i(?:32|64)|copysign|ctz|demote\/f64|div(?:_[su])?|eqz?|extend_[su]\/i32|floor|ge(?:_[su])?|gt(?:_[su])?|le(?:_[su])?|load(?:(?:8|16|32)_[su])?|lt(?:_[su])?|max|min|mul|nearest|neg?|or|popcnt|promote\/f32|reinterpret\/[fi](?:32|64)|rem_[su]|rot[lr]|shl|shr_[su]|store(?:8|16|32)?|sqrt|sub|trunc(?:_[su]\/f(?:32|64))?|wrap\/i64|xor))\b/
      )

      offset_align = Mode.new.apply(
        match: [
          /(?:offset|align)/,
          /\s*/,
          /=/,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "operator",
        }
      )

      Mode.new.apply(
        name: "WebAssembly",
        keywords: {
          "$pattern" => "[\\w.]+",
          "keyword"  => kws,
        } of String => KeywordsVal,
        contains: [
          line_comment,
          block_comment,
          offset_align,
          argument,
          parens,
          function_reference,
          MODES::QUOTE_STRING_MODE,
          type_mode,
          math_operations,
          number,
        ] of Mode
      )
    end
  end

  Languages.register("wasm", ->(hljs : HLJS) { Wasm.defined(hljs) })
end
