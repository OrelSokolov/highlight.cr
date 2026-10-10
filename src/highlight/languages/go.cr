# Порт lib/languages/go.js (highlight.js 11.12.0).

module Highlight::Languages
  module Go
    def self.defined(hljs : HLJS) : Mode
      literals = [
        "true",
        "false",
        "iota",
        "nil",
      ]
      built_ins = [
        "append",
        "cap",
        "close",
        "complex",
        "copy",
        "imag",
        "len",
        "make",
        "new",
        "panic",
        "print",
        "println",
        "real",
        "recover",
        "delete",
      ]
      types = [
        "bool",
        "byte",
        "complex64",
        "complex128",
        "error",
        "float32",
        "float64",
        "int8",
        "int16",
        "int32",
        "int64",
        "string",
        "uint8",
        "uint16",
        "uint32",
        "uint64",
        "int",
        "uint",
        "uintptr",
        "rune",
      ]
      kws = [
        "break",
        "case",
        "chan",
        "const",
        "continue",
        "default",
        "defer",
        "else",
        "fallthrough",
        "for",
        "func",
        "go",
        "goto",
        "if",
        "import",
        "interface",
        "map",
        "package",
        "range",
        "return",
        "select",
        "struct",
        "switch",
        "type",
        "var",
      ]
      keywords = {} of String => KeywordsVal
      keywords["keyword"] = kws
      keywords["type"] = types
      keywords["literal"] = literals
      keywords["built_in"] = built_ins

      Mode.new.apply(
        name: "Go",
        aliases: ["golang"],
        keywords: keywords,
        illegal: "</",
        contains: [
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
          Mode.new.apply(
            class_name: "string",
            variants: [
              MODES::QUOTE_STRING_MODE,
              MODES::APOS_STRING_MODE,
              Mode.new.apply(
                begin: "`",
                end: "`"
              ),
            ] of Mode
          ),
          Mode.new.apply(
            class_name: "number",
            variants: [
              Mode.new.apply(
                # hex without a present digit before . (making a digit afterwards required)
                match: /-?\b0[xX]\.[a-fA-F0-9](_?[a-fA-F0-9])*[pP][+-]?\d(_?\d)*i?/,
                relevance: 0
              ),
              Mode.new.apply(
                # hex with a present digit before . (making a digit afterwards optional)
                match: /-?\b0[xX](_?[a-fA-F0-9])+((\.([a-fA-F0-9](_?[a-fA-F0-9])*)?)?[pP][+-]?\d(_?\d)*)?i?/,
                relevance: 0
              ),
              Mode.new.apply(
                match: /-?\b0[oO](_?[0-7])*i?/, # leading 0o octal
                relevance: 0
              ),
              Mode.new.apply(
                match: /-?\b0[bB](_?[01])*i?/, # leading 0b binary
                relevance: 0
              ),
              Mode.new.apply(
                # decimal without a present digit before . (making a digit afterwards required)
                match: /-?\.\d(_?\d)*([eE][+-]?\d(_?\d)*)?i?/,
                relevance: 0
              ),
              Mode.new.apply(
                # decimal with a present digit before . (making a digit afterwards optional)
                match: /-?\b\d(_?\d)*(\.(\d(_?\d)*)?)?([eE][+-]?\d(_?\d)*)?i?/,
                relevance: 0
              ),
            ] of Mode
          ),
          Mode.new.apply(begin: /:=/ # relevance booster
          ),
          Mode.new.apply(
            class_name: "function",
            begin_keywords: "func",
            end: "\\s*(\\{|$)",
            exclude_end: true,
            contains: [
              MODES::TITLE_MODE,
              Mode.new.apply(
                class_name: "params",
                begin: /\(/,
                end: /\)/,
                ends_parent: true,
                keywords: keywords,
                illegal: /["']/
              ),
            ] of Mode
          ),
        ] of Mode
      )
    end
  end

  Languages.register("go", ->(hljs : HLJS) { Go.defined(hljs) })
end
