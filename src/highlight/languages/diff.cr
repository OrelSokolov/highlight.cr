# Порт lib/languages/diff.js (highlight.js 11.12.0).

module Highlight::Languages
  module Diff
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      Mode.new.apply(
        name: "Diff",
        aliases: ["patch"],
        contains: [
          Mode.new.apply(
            class_name: "meta",
            relevance: 10,
            match: regex.either([
              /^@@ +-\d+,\d+ +\+\d+,\d+ +@@/, # @@ -1,2 +1,2 @@
              /^@@ +-\d+ +\+\d+,\d+ +@@/,     # @@ -1 +1,2 @@
              /^@@ +-\d+,\d+ +\+\d+ +@@/,     # @@ -1,2 +1 @@
              /^@@ +-\d+ +\+\d+ +@@/,         # @@ -1 +1 @@
              /^\*\*\* +\d+,\d+ +\*\*\*\*$/,
              /^--- +\d+,\d+ +----$/,
            ])
          ),
          Mode.new.apply(
            class_name: "comment",
            variants: [
              Mode.new.apply(
                begin: regex.either([
                  /Index: /,
                  /^index/,
                  /={3,}/,
                  /^-{3}/,
                  /^\*{3} /,
                  /^\+{3}/,
                  /^diff --git/,
                ]),
                end: /$/
              ),
              Mode.new.apply(match: /^\*{15}$/),
            ] of Mode
          ),
          Mode.new.apply(
            class_name: "addition",
            begin: /^\+/,
            end: /$/
          ),
          Mode.new.apply(
            class_name: "deletion",
            begin: /^-/,
            end: /$/
          ),
          Mode.new.apply(
            class_name: "addition",
            begin: /^!/,
            end: /$/
          ),
        ] of Mode
      )
    end
  end

  Languages.register("diff", ->(hljs : HLJS) { Diff.defined(hljs) })
end
