# Порт lib/languages/dockerfile.js (highlight.js 11.12.0).

module Highlight::Languages
  module Dockerfile
    def self.defined(hljs : HLJS) : Mode
      Mode.new.apply(
        name: "Dockerfile",
        aliases: [
          "docker",
        ],
        case_insensitive: true,
        keywords: "from maintainer expose env arg user onbuild stopsignal",
        contains: [
          MODES::HASH_COMMENT_MODE,
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
          MODES::NUMBER_MODE,
          # Инструкции с shell-аргументами: до конца строки — bash
          Mode.new.apply(
            begin_keywords: "run cmd entrypoint volume add copy workdir label healthcheck shell",
            starts: Mode.new.apply(
              end: /[^\\]$/,
              sub_language: "bash"
            )
          ),
        ] of Mode,
        illegal: "</"
      )
    end
  end

  Languages.register("dockerfile", ->(hljs : HLJS) { Dockerfile.defined(hljs) })
end
