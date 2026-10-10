# Порт lib/languages/scss.js (highlight.js 11.12.0).
# Списки имён общие с css.js — переиспользуются из Css.
# VALUE_KEYWORDS извлечена из оригинала скриптом (не вручную).

module Highlight::Languages
  module Scss
    VALUE_KEYWORDS = "\\b(whitespace|wait|w-resize|visible|vertical-text|vertical-ideographic|uppercase|upper-roman|upper-alpha|underline|transparent|top|thin|thick|text|text-top|text-bottom|tb-rl|table-header-group|table-footer-group|sw-resize|super|strict|static|square|solid|small-caps|separate|se-resize|scroll|s-resize|rtl|row-resize|ridge|right|repeat|repeat-y|repeat-x|relative|progress|pointer|overline|outside|outset|oblique|nowrap|not-allowed|normal|none|nw-resize|no-repeat|no-drop|newspaper|ne-resize|n-resize|move|middle|medium|ltr|lr-tb|lowercase|lower-roman|lower-alpha|loose|list-item|line|line-through|line-edge|lighter|left|keep-all|justify|italic|inter-word|inter-ideograph|inside|inset|inline|inline-block|inherit|inactive|ideograph-space|ideograph-parenthesis|ideograph-numeric|ideograph-alpha|horizontal|hidden|help|hand|groove|fixed|ellipsis|e-resize|double|dotted|distribute|distribute-space|distribute-letter|distribute-all-lines|disc|disabled|default|decimal|dashed|crosshair|collapse|col-resize|circle|char|center|capitalize|break-word|break-all|bottom|both|bolder|bold|block|bidi-override|below|baseline|auto|always|all-scroll|absolute|table|table-cell)\\b"


    IDENT_RE = "[a-zA-Z-][a-zA-Z0-9_-]*"

    def self.defined(hljs : HLJS) : Mode
      modes_important = Mode.new.apply(
        scope: "meta",
        begin: "!important"
      )
      block_comment = MODES::C_BLOCK_COMMENT_MODE
      hexcolor = Mode.new.apply(
        scope: "number",
        begin: "#(([0-9a-fA-F]{3,4})|(([0-9a-fA-F]{2}){3,4}))\\b"
      )
      unicode_range = Mode.new.apply(
        scope: "number",
        begin: "\\b[Uu]\\+[0-9A-Fa-f][0-9A-Fa-f?]{0,5}(-[0-9A-Fa-f][0-9A-Fa-f]{0,5})?"
      )
      function_dispatch = Mode.new.apply(
        class_name: "built_in",
        begin: "[\\w-]+(?=\\()"
      )
      attribute_selector_mode = Mode.new.apply(
        scope: "selector-attr",
        begin: "\\[",
        end: "\\]",
        illegal: "$",
        contains: [
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
        ] of Mode
      )
      css_number_mode = Mode.new.apply(
        scope: "number",
        begin: NUMBER_RE + "(" +
               "%|em|ex|ch|rem" +
               "|vw|vh|vmin|vmax" +
               "|cm|mm|in|pt|pc|px" +
               "|deg|grad|rad|turn" +
               "|s|ms" +
               "|Hz|kHz" +
               "|dpi|dpcm|dppx" +
               ")?",
        relevance: 0
      )
      css_variable = Mode.new.apply(
        class_name: "attr",
        begin: "--[A-Za-z_][A-Za-z0-9_-]*"
      )

      at_identifier = "@[a-z-]+" # @font-face
      at_modifiers = "and or not only"
      variable = Mode.new.apply(
        class_name: "variable",
        begin: "(\\$" + IDENT_RE + ")\\b",
        relevance: 0
      )

      Mode.new.apply(
        name: "SCSS",
        case_insensitive: true,
        illegal: "[=/|']",
        contains: [
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
          # to recognize keyframe 40% etc which are outside the scope of our
          # attribute value mode
          css_number_mode,
          Mode.new.apply(
            class_name: "selector-id",
            begin: "#[A-Za-z0-9_-]+",
            relevance: 0
          ),
          Mode.new.apply(
            class_name: "selector-class",
            begin: "\\.[A-Za-z0-9_-]+",
            relevance: 0
          ),
          attribute_selector_mode,
          Mode.new.apply(
            class_name: "selector-tag",
            begin: "\\b(" + Css::TAGS.join("|") + ")\\b",
            # was there, before, but why?
            relevance: 0
          ),
          Mode.new.apply(
            class_name: "selector-pseudo",
            begin: ":(" + Css::PSEUDO_CLASSES.join("|") + ")"
          ),
          Mode.new.apply(
            class_name: "selector-pseudo",
            begin: ":(:)?(" + Css::PSEUDO_ELEMENTS.join("|") + ")"
          ),
          variable,
          # pseudo-selector params
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            contains: [css_number_mode] of Mode
          ),
          css_variable,
          Mode.new.apply(
            class_name: "attribute",
            begin: "\\b(" + Css::ATTRIBUTES.join("|") + ")\\b"
          ),
          Mode.new.apply(begin: VALUE_KEYWORDS),
          Mode.new.apply(
            begin: ":",
            end: "[;}{]",
            relevance: 0,
            contains: [
              block_comment,
              variable,
              hexcolor,
              css_number_mode,
              unicode_range,
              MODES::QUOTE_STRING_MODE,
              MODES::APOS_STRING_MODE,
              modes_important,
              function_dispatch,
            ] of Mode
          ),
          # matching these here allows us to treat them more like regular CSS
          # rules so everything between the {} gets regular rule highlighting,
          # which is what we want for page and font-face
          Mode.new.apply(
            begin: "@(page|font-face)",
            keywords: {
              "$pattern" => at_identifier,
              "keyword"  => "@page @font-face",
            } of String => KeywordsVal
          ),
          Mode.new.apply(
            begin: "@",
            end: "[{;]",
            return_begin: true,
            keywords: {
              "$pattern"  => "[a-z-]+",
              "keyword"   => at_modifiers,
              "attribute" => Css::MEDIA_FEATURES.join(" "),
            } of String => KeywordsVal,
            contains: [
              Mode.new.apply(
                begin: at_identifier,
                class_name: "keyword"
              ),
              Mode.new.apply(
                begin: "[a-z-]+(?=:)",
                class_name: "attribute"
              ),
              variable,
              MODES::QUOTE_STRING_MODE,
              MODES::APOS_STRING_MODE,
              hexcolor,
              css_number_mode,
            ] of Mode
          ),
          function_dispatch,
        ] of Mode
      )
    end
  end

  Languages.register("scss", ->(hljs : HLJS) { Scss.defined(hljs) })
end
