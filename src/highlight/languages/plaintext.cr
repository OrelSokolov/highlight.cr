# Порт lib/languages/plaintext.js (highlight.js 11.12.0).

module Highlight::Languages
  module Plaintext
    def self.defined(hljs : HLJS) : Mode
      Mode.new.apply(
        name: "Plain text",
        aliases: [
          "text",
          "txt",
        ],
        disable_autodetect: true
      )
    end
  end

  Languages.register("plaintext", ->(hljs : HLJS) { Plaintext.defined(hljs) })
end
