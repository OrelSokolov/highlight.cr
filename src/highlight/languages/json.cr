# Порт lib/languages/json.js (highlight.js 11.12.0).

module Highlight::Languages
  module JsonLang
    def self.defined(hljs : HLJS) : Mode
      extended_number_re = "([-+]?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)|NaN|[-+]?Infinity" # 0x..., 0..., decimal, float

      extended_number_mode = Mode.new.apply(
        scope: "number",
        match: extended_number_re,
        relevance: 0
      )

      attribute = Mode.new.apply(
        class_name: "attr",
        begin: /(("(\\.|[^\\"\r\n])*")|('(\\.|[^\\'\r\n])*'))(?=\s*:)/,
        relevance: 1.01
      )
      punctuation = Mode.new.apply(
        match: %r([{}[\],:]),
        class_name: "punctuation",
        relevance: 0
      )
      literals = [
        "true",
        "false",
        "null",
      ]
      # NOTE: normally we would rely on `keywords` for this but using a mode here allows us
      # - to use the very tight `illegal: \S` rule later to flag any other character
      # - as illegal indicating that despite looking like JSON we do not truly have
      # - JSON and thus improve false-positively greatly since JSON will try and claim
      # - all sorts of JSON looking stuff
      literals_mode = Mode.new.apply(
        scope: "literal",
        begin_keywords: literals.join(" ")
      )

      keywords = {} of String => KeywordsVal
      keywords["literal"] = literals

      Mode.new.apply(
        name: "JSON",
        aliases: ["jsonc", "json5"],
        keywords: keywords,
        contains: [
          attribute,
          punctuation,
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
          literals_mode,
          extended_number_mode,
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
        ] of Mode,
        illegal: "\\S"
      )
    end
  end

  Languages.register("json", ->(hljs : HLJS) { JsonLang.defined(hljs) })
end
