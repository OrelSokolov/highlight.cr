# Порт lib/languages/php-template.js (highlight.js 11.12.0).

module Highlight::Languages
  module PhpTemplate
    def self.defined(hljs : HLJS) : Mode
      Mode.new.apply(
        name: "PHP template",
        sub_language: "xml",
        contains: [
          Mode.new.apply(
            begin: "<\\?(php|=)?",
            end: "\\?>",
            sub_language: "php",
            contains: [
              # We don't want the php closing tag ?> to close the PHP block when
              # inside any of the following blocks:
              Mode.new.apply(
                begin: "/\\*",
                end: "\\*/",
                skip: true
              ),
              Mode.new.apply(
                begin: "b\"",
                end: "\"",
                skip: true
              ),
              Mode.new.apply(
                begin: "b'",
                end: "'",
                skip: true
              ),
              MODES::APOS_STRING_MODE.inherit(Mode.new.apply(skip: true),
                clear_scope: true, clear_illegal: true, clear_contains: true),
              MODES::QUOTE_STRING_MODE.inherit(Mode.new.apply(skip: true),
                clear_scope: true, clear_illegal: true, clear_contains: true),
            ] of Mode
          ),
        ] of Mode
      )
    end
  end

  Languages.register("php-template", ->(hljs : HLJS) { PhpTemplate.defined(hljs) })
end
