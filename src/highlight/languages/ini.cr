# Порт lib/languages/ini.js (highlight.js 11.12.0).

module Highlight::Languages
  module Ini
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      numbers = Mode.new.apply(
        class_name: "number",
        relevance: 0,
        variants: [
          Mode.new.apply(begin: /([+-]+)?[\d]+_[\d_]+/),
          Mode.new.apply(begin: NUMBER_RE),
        ] of Mode
      )
      comments = hljs.comment(nil, nil)
      comments.variants = [
        Mode.new.apply(
          begin: /;/,
          end: /$/
        ),
        Mode.new.apply(
          begin: /#/,
          end: /$/
        ),
      ] of Mode
      variables = Mode.new.apply(
        class_name: "variable",
        variants: [
          Mode.new.apply(begin: /\$[\w\d"][\w\d_]*/),
          Mode.new.apply(begin: /\$\{(.*?)\}/),
        ] of Mode
      )
      literals = Mode.new.apply(
        class_name: "literal",
        begin: /\bon|off|true|false|yes|no\b/
      )
      strings = Mode.new.apply(
        class_name: "string",
        contains: [MODES::BACKSLASH_ESCAPE] of Mode,
        variants: [
          Mode.new.apply(
            begin: "'''",
            end: "'''",
            relevance: 10
          ),
          Mode.new.apply(
            begin: "\"\"\"",
            end: "\"\"\"",
            relevance: 10
          ),
          Mode.new.apply(
            begin: "\"",
            end: "\""
          ),
          Mode.new.apply(
            begin: "'",
            end: "'"
          ),
        ] of Mode
      )
      array = Mode.new.apply(
        begin: /\[/,
        end: /\]/,
        contains: [
          comments,
          literals,
          variables,
          strings,
          numbers,
          Mode.self_marker,
        ] of Mode,
        relevance: 0
      )

      bare_key = /[A-Za-z0-9_-]+/
      quoted_key_double_quote = /"(\\"|[^"])*"/
      quoted_key_single_quote = /'[^']*'/
      any_key = regex.either([
        bare_key, quoted_key_double_quote, quoted_key_single_quote,
      ])
      dotted_key = regex.concat(
        any_key, "(\\s*\\.\\s*", any_key, ")*",
        regex.lookahead(/\s*=\s*[^#\s]/)
      )

      Mode.new.apply(
        name: "TOML, also INI",
        aliases: ["toml"],
        case_insensitive: true,
        illegal: /\S/,
        contains: [
          comments,
          Mode.new.apply(
            class_name: "section",
            begin: /\[+/,
            end: /\]+/
          ),
          Mode.new.apply(
            begin: dotted_key,
            class_name: "attr",
            starts: Mode.new.apply(
              end: /$/,
              contains: [
                comments,
                array,
                literals,
                variables,
                strings,
                numbers,
              ] of Mode
            )
          ),
        ] of Mode
      )
    end
  end

  Languages.register("ini", ->(hljs : HLJS) { Ini.defined(hljs) })
end
