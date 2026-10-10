# Порт lib/languages/less.js (highlight.js 11.12.0).
# Списки имён общие с css.js — переиспользуются из Css.

module Highlight::Languages
  module Less
    def self.string_mode(c : String) : Mode
      # Less strings are not multiline (also include '~' for more consistent
      # coloring of "escaped" strings)
      Mode.new.apply(
        class_name: "string",
        begin: "~?" + c + ".*?" + c
      )
    end

    def self.ident_mode(name : String, begin_p : String, relevance : Int32 | Float64 | Nil = nil) : Mode
      Mode.new.apply(
        class_name: name,
        begin: begin_p,
        relevance: relevance
      )
    end

    def self.defined(hljs : HLJS) : Mode
      modes_important = Mode.new.apply(
        scope: "meta",
        begin: "!important"
      )
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

      pseudo_selectors = (Css::PSEUDO_CLASSES + Css::PSEUDO_ELEMENTS).sort.reverse

      at_modifiers = "and or not only"
      ident_re = "[\\w-]+" # yes, Less identifiers may begin with a digit
      interp_ident_re = "(" + ident_re + "|@\\{" + ident_re + "\\})"

      # --- Generic Modes ---

      rules = [] of Mode          # forward def. for recursive modes
      value_modes = [] of Mode    # forward def. for recursive modes

      at_keywords = {
        "$pattern"  => "[a-z-]+",
        "keyword"   => at_modifiers,
        "attribute" => Css::MEDIA_FEATURES.join(" "),
      } of String => KeywordsVal

      parens_mode = Mode.new.apply(
        # used only to properly balance nested parens inside mixin call,
        # def. arg list
        begin: "\\(",
        end: "\\)",
        contains: value_modes,
        keywords: at_keywords,
        relevance: 0
      )

      # generic Less highlighter (used almost everywhere except selectors):
      value_modes.concat([
        MODES::C_LINE_COMMENT_MODE,
        MODES::C_BLOCK_COMMENT_MODE,
        string_mode("'"),
        string_mode("\""),
        css_number_mode, # fixme: it does not include dot for numbers like .5em :(
        Mode.new.apply(
          begin: "(url|data-uri)\\(",
          starts: Mode.new.apply(
            class_name: "string",
            end: "[\\)\\n]",
            exclude_end: true
          )
        ),
        unicode_range,
        hexcolor,
        parens_mode,
        ident_mode("variable", "@@?" + ident_re, 10),
        ident_mode("variable", "@\\{" + ident_re + "\\}"),
        ident_mode("built_in", "~?`[^`]*?`"), # inline javascript (or whatever host language) *multiline* string
        # @media features (it’s here to not duplicate things in AT_RULE_MODE
        # with extra PARENS_MODE overriding):
        Mode.new.apply(
          class_name: "attribute",
          begin: ident_re + "\\s*:",
          end: ":",
          return_begin: true,
          exclude_end: true
        ),
        modes_important,
        Mode.new.apply(begin_keywords: "and not"),
        function_dispatch,
      ] of Mode)

      value_with_rulesets = value_modes + [Mode.new.apply(
        begin: /\{/,
        end: /\}/,
        contains: rules
      )] of Mode

      mixin_guard_mode = Mode.new.apply(
        begin_keywords: "when",
        ends_with_parent: true,
        # using this form to override VALUE’s 'function' match
        contains: [Mode.new.apply(begin_keywords: "and not")] of Mode + value_modes
      )

      # --- Rule-Level Modes ---

      rule_mode = Mode.new.apply(
        begin: interp_ident_re + "\\s*:",
        return_begin: true,
        end: /[;}]/,
        relevance: 0,
        contains: [
          Mode.new.apply(begin: /-(webkit|moz|ms|o)-/),
          css_variable,
          Mode.new.apply(
            class_name: "attribute",
            begin: "\\b(" + Css::ATTRIBUTES.join("|") + ")\\b",
            end: /(?=:)/,
            starts: Mode.new.apply(
              ends_with_parent: true,
              illegal: "[<=$]",
              relevance: 0,
              contains: value_modes
            )
          ),
        ] of Mode
      )

      at_rule_mode = Mode.new.apply(
        class_name: "keyword",
        begin: "@(import|media|charset|font-face|(-[a-z]+-)?keyframes|supports|document|namespace|page|viewport|host)\\b",
        starts: Mode.new.apply(
          end: "[;{}]",
          keywords: at_keywords,
          return_end: true,
          contains: value_modes,
          relevance: 0
        )
      )

      # variable definitions and calls
      var_rule_mode = Mode.new.apply(
        class_name: "variable",
        variants: [
          # using more strict pattern for higher relevance to increase chances
          # of Less detection. this is *the only* Less specific statement used
          # in most of the sources, so...
          # (we’ll still often loose to the css-parser unless there's '//'
          # comment, simply because 1 variable just can't beat 99 properties :)
          Mode.new.apply(
            begin: "@" + ident_re + "\\s*:",
            relevance: 15
          ),
          Mode.new.apply(begin: "@" + ident_re),
        ] of Mode,
        starts: Mode.new.apply(
          end: "[;}]",
          return_end: true,
          contains: value_with_rulesets
        )
      )

      selector_mode = Mode.new.apply(
        # first parse unambiguous selectors (i.e. those not starting with tag)
        # then fall into the scary lookahead-discriminator variant.
        # this mode also handles mixin definitions and calls
        variants: [
          Mode.new.apply(
            begin: "[\\.#:&\\[>]",
            end: "[;{}]" # mixin calls end with ';'
          ),
          Mode.new.apply(
            begin: interp_ident_re,
            end: /\{/
          ),
        ] of Mode,
        return_begin: true,
        return_end: true,
        illegal: "[<='\"$]",
        relevance: 0,
        contains: [
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
          mixin_guard_mode,
          ident_mode("keyword", "all\\b"),
          ident_mode("variable", "@\\{" + ident_re + "\\}"), # otherwise it’s identified as tag
          Mode.new.apply(
            begin: "\\b(" + Css::TAGS.join("|") + ")\\b",
            class_name: "selector-tag"
          ),
          css_number_mode,
          ident_mode("selector-tag", interp_ident_re, 0),
          ident_mode("selector-id", "#" + interp_ident_re),
          ident_mode("selector-class", "\\." + interp_ident_re, 0),
          ident_mode("selector-tag", "&", 0),
          attribute_selector_mode,
          Mode.new.apply(
            class_name: "selector-pseudo",
            begin: ":(" + Css::PSEUDO_CLASSES.join("|") + ")"
          ),
          Mode.new.apply(
            class_name: "selector-pseudo",
            begin: ":(:)?(" + Css::PSEUDO_ELEMENTS.join("|") + ")"
          ),
          # argument list of parametric mixins
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            relevance: 0,
            contains: value_with_rulesets
          ),
          # eat !important after mixin call or it will be colored as tag
          Mode.new.apply(begin: "!important"),
          function_dispatch,
        ] of Mode
      )

      pseudo_selector_mode = Mode.new.apply(
        begin: ident_re + ":(:)?" + "(" + pseudo_selectors.join("|") + ")",
        return_begin: true,
        contains: [selector_mode] of Mode
      )

      rules.concat([
        MODES::C_LINE_COMMENT_MODE,
        MODES::C_BLOCK_COMMENT_MODE,
        at_rule_mode,
        var_rule_mode,
        pseudo_selector_mode,
        rule_mode,
        selector_mode,
        mixin_guard_mode,
        function_dispatch,
      ] of Mode)

      Mode.new.apply(
        name: "Less",
        case_insensitive: true,
        illegal: "[=>'\\/<($\"]",
        contains: rules
      )
    end
  end

  Languages.register("less", ->(hljs : HLJS) { Less.defined(hljs) })
end
