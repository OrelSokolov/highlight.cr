# Порт lib/languages/markdown.js (highlight.js 11.12.0).

module Highlight::Languages
  module Markdown
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers

      inline_html = Mode.new.apply(
        begin: /<\/?[A-Za-z_]/,
        end: ">",
        sub_language: "xml",
        relevance: 0
      )
      # https://spec.commonmark.org/0.31.2/#thematic-breaks
      # three or more `-`, `*` or `_`, all the same character, optionally
      # separated and followed by spaces or tabs, and nothing else on the line
      horizontal_rule = Mode.new.apply(
        match: "^ {0,3}([-*_])[ \\t]*(?:\\1[ \\t]*){2,}$"
      )
      code = Mode.new.apply(
        class_name: "code",
        variants: [
          # TODO: fix to allow these to work with sublanguage also
          Mode.new.apply(begin: "(`{3,})[^`](.|\\n)*?\\1`*[ ]*"),
          Mode.new.apply(begin: "(~{3,})[^~](.|\\n)*?\\1~*[ ]*"),
          # needed to allow markdown as a sublanguage to work
          Mode.new.apply(
            begin: "```",
            end: "```+[ ]*$"
          ),
          Mode.new.apply(
            begin: "~~~",
            end: "~~~+[ ]*$"
          ),
          Mode.new.apply(begin: "`.+?`"),
          Mode.new.apply(
            begin: "(?=^( {4}|\\t))",
            # use contains to gobble up multiple lines to allow the block to be whatever size
            # but only have a single open/close tag vs one per line
            contains: [
              Mode.new.apply(
                begin: "^( {4}|\\t)",
                end: "(\\n)$"
              ),
            ] of Mode,
            relevance: 0
          ),
        ] of Mode
      )
      list = Mode.new.apply(
        class_name: "bullet",
        begin: "^[ \\t]*([*+-]|(\\d+\\.))(?=\\s+)",
        end: "\\s+",
        exclude_end: true
      )
      link_reference = Mode.new.apply(
        begin: /^\[[^\n]+\]:/,
        return_begin: true,
        contains: [
          Mode.new.apply(
            class_name: "symbol",
            begin: /\[/,
            end: /\]/,
            exclude_begin: true,
            exclude_end: true
          ),
          Mode.new.apply(
            class_name: "link",
            begin: /:\s*/,
            end: /$/,
            exclude_begin: true
          ),
        ] of Mode
      )
      url_scheme = /[A-Za-z][A-Za-z0-9+.-]*/
      link = Mode.new.apply(
        variants: [
          # too much like nested array access in so many languages
          # to have any real relevance
          Mode.new.apply(
            begin: /\[.+?\]\[.*?\]/,
            relevance: 0
          ),
          # popular internet URLs
          Mode.new.apply(
            begin: /\[.+?\]\(((data|javascript|mailto):|(?:http|ftp)s?:\/\/).*?\)/,
            relevance: 2
          ),
          Mode.new.apply(
            begin: regex.concat(/\[.+?\]\(/, url_scheme, /:\/\/.*?\)/),
            relevance: 2
          ),
          # relative urls
          Mode.new.apply(
            begin: "\\[.+?\\]\\([./?&#].*?\\)",
            relevance: 1
          ),
          # whatever else, lower relevance (might not be a link at all)
          Mode.new.apply(
            begin: /\[.*?\]\(.*?\)/,
            relevance: 0
          ),
        ] of Mode,
        return_begin: true,
        contains: [
          Mode.new.apply(
            # empty strings for alt or link text
            match: /\[(?=\])/
          ),
          Mode.new.apply(
            class_name: "string",
            relevance: 0,
            begin: "\\[",
            end: "\\]",
            exclude_begin: true,
            return_end: true
          ),
          Mode.new.apply(
            class_name: "link",
            relevance: 0,
            begin: "\\]\\(",
            end: "\\)",
            exclude_begin: true,
            exclude_end: true
          ),
          Mode.new.apply(
            class_name: "symbol",
            relevance: 0,
            begin: "\\]\\[",
            end: "\\]",
            exclude_begin: true,
            exclude_end: true
          ),
        ] of Mode
      )
      bold = Mode.new.apply(
        class_name: "strong",
        contains: [] of Mode, # defined later
        variants: [
          Mode.new.apply(
            begin: /_{2}(?!\s)/,
            end: /_{2}/
          ),
          Mode.new.apply(
            begin: /\*{2}(?!\s)/,
            end: /\*{2}/
          ),
        ] of Mode
      )
      italic = Mode.new.apply(
        class_name: "emphasis",
        contains: [] of Mode, # defined later
        variants: [
          Mode.new.apply(
            begin: /\*(?![*\s])/,
            end: /\*/
          ),
          Mode.new.apply(
            begin: /_(?![_\s])/,
            end: /_/,
            relevance: 0
          ),
        ] of Mode
      )

      # 3 level deep nesting is not allowed because it would create confusion
      # in cases like `***testing***` because where we don't know if the last
      # `***` is starting a new bold/italic or finishing the last one
      bold_without_italic = bold.inherit(Mode.new.apply(contains: [] of Mode))
      italic_without_bold = italic.inherit(Mode.new.apply(contains: [] of Mode))
      bold.contains.not_nil! << italic_without_bold
      italic.contains.not_nil! << bold_without_italic

      containable = [
        inline_html,
        link,
      ] of Mode

      [bold, italic, bold_without_italic, italic_without_bold].each do |m|
        m.contains = m.contains.not_nil! + containable
      end

      containable = containable + [bold, italic]

      header = Mode.new.apply(
        class_name: "section",
        variants: [
          Mode.new.apply(
            begin: %q(^#{1,6}),
            end: "$",
            contains: containable
          ),
          Mode.new.apply(
            begin: "(?=^.+?\\n[=-]{2,}$)",
            contains: [
              Mode.new.apply(begin: "^[=-]*$"),
              Mode.new.apply(
                begin: "^",
                end: "\\n",
                contains: containable
              ),
            ] of Mode
          ),
        ] of Mode
      )

      blockquote = Mode.new.apply(
        class_name: "quote",
        begin: "^>\\s+",
        contains: containable,
        end: "$"
      )

      entity = Mode.new.apply(
        # https://spec.commonmark.org/0.31.2/#entity-references
        scope: "literal",
        match: "&([a-zA-Z0-9]+|#[0-9]{1,7}|#[Xx][0-9a-fA-F]{1,6});"
      )

      Mode.new.apply(
        name: "Markdown",
        aliases: [
          "md",
          "mkdown",
          "mkd",
        ],
        contains: [
          header,
          inline_html,
          list,
          # must come before BOLD/ITALIC so that a `***` or `___` thematic break
          # isn't mistaken for the start of bold text
          horizontal_rule,
          bold,
          italic,
          blockquote,
          code,
          link,
          link_reference,
          entity,
        ] of Mode
      )
    end
  end

  Languages.register("markdown", ->(hljs : HLJS) { Markdown.defined(hljs) })
end
