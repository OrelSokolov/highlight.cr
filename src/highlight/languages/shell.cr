# Порт lib/languages/shell.js (highlight.js 11.12.0).

module Highlight::Languages
  module Shell
    def self.defined(hljs : HLJS) : Mode
      Mode.new.apply(
        name: "Shell Session",
        aliases: [
          "console",
          "shellsession",
        ],
        contains: [
          Mode.new.apply(
            class_name: "meta.prompt",
            # We cannot add \s (spaces) in the regular expression otherwise it will be too broad and produce unexpected result.
            # For instance, in the following example, it would match "echo /path/to/home >" as a prompt:
            # echo /path/to/home > t.exe
            begin: %r(^\s{0,3}[./~\w\d[\]()@-]*[>%$#][ ]?),
            starts: Mode.new.apply(
              end: /[^\\](?=\s*$)/,
              sub_language: "bash"
            )
          ),
        ] of Mode
      )
    end
  end

  Languages.register("shell", ->(hljs : HLJS) { Shell.defined(hljs) })
end
