# Порт lib/languages/erb.js (highlight.js 11.12.0).

module Highlight::Languages
  module Erb
    def self.defined(hljs : HLJS) : Mode
      Mode.new.apply(
        name: "ERB",
        sub_language: "xml",
        contains: [
          hljs.comment("<%#", "%>"),
          Mode.new.apply(
            begin: "<%[%=-]?",
            end: "[%-]?%>",
            sub_language: "ruby",
            exclude_begin: true,
            exclude_end: true
          ),
        ] of Mode
      )
    end
  end

  Languages.register("erb", ->(hljs : HLJS) { Erb.defined(hljs) })
end
