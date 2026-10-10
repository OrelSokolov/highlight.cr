# Порт lib/languages/python-repl.js (highlight.js 11.12.0).

module Highlight::Languages
  module PythonRepl
    def self.defined(hljs : HLJS) : Mode
      Mode.new.apply(
        aliases: ["pycon"],
        contains: [
          Mode.new.apply(
            class_name: "meta.prompt",
            starts: Mode.new.apply(
              # a space separates the REPL prefix from the actual code
              # this is purely for cleaner HTML output
              end: / |$/,
              starts: Mode.new.apply(
                end: "$",
                sub_language: "python"
              )
            ),
            variants: [
              Mode.new.apply(begin: /^>>>(?=[ ]|$)/),
              Mode.new.apply(begin: /^\.\.\.(?=[ ]|$)/),
            ] of Mode
          ),
        ] of Mode
      )
    end
  end

  Languages.register("python-repl", ->(hljs : HLJS) { PythonRepl.defined(hljs) })
end
