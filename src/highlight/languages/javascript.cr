# Порт lib/languages/typescript.js, строки 1-770 = javascript.js
# (highlight.js 11.12.0). Shared-константы используются и typescript.cr.

module Highlight::Languages
  module JavascriptLang
    IDENT_RE_JS = "[A-Za-z$_][0-9A-Za-z$_]*"

    KEYWORDS_JS = [
      "as", # for exports
      "in",
      "of",
      "if",
      "for",
      "while",
      "finally",
      "var",
      "new",
      "function",
      "do",
      "return",
      "void",
      "else",
      "break",
      "catch",
      "instanceof",
      "with",
      "throw",
      "case",
      "default",
      "try",
      "switch",
      "continue",
      "typeof",
      "delete",
      "let",
      "yield",
      "const",
      "class",
      # JS handles these with a special rule
      # "get",
      # "set",
      "debugger",
      "async",
      "await",
      "static",
      "import",
      "from",
      "export",
      "extends",
      # It's reached stage 3, which is "recommended for implementation":
      "using",
    ]

    LITERALS_JS = [
      "true",
      "false",
      "null",
      "undefined",
      "NaN",
      "Infinity",
    ]

    # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects
    TYPES_JS = [
      # Fundamental objects
      "Object",
      "Function",
      "Boolean",
      "Symbol",
      # numbers and dates
      "Math",
      "Date",
      "Number",
      "BigInt",
      # text
      "String",
      "RegExp",
      # Indexed collections
      "Array",
      "Float32Array",
      "Float64Array",
      "Int8Array",
      "Uint8Array",
      "Uint8ClampedArray",
      "Int16Array",
      "Int32Array",
      "Uint16Array",
      "Uint32Array",
      "BigInt64Array",
      "BigUint64Array",
      # Keyed collections
      "Set",
      "Map",
      "WeakSet",
      "WeakMap",
      # Structured data
      "ArrayBuffer",
      "SharedArrayBuffer",
      "Atomics",
      "DataView",
      "JSON",
      # Control abstraction objects
      "Promise",
      "Generator",
      "GeneratorFunction",
      "AsyncFunction",
      # Reflection
      "Reflect",
      "Proxy",
      # Internationalization
      "Intl",
      # WebAssembly
      "WebAssembly",
    ]

    ERROR_TYPES_JS = [
      "Error",
      "EvalError",
      "InternalError",
      "RangeError",
      "ReferenceError",
      "SyntaxError",
      "TypeError",
      "URIError",
    ]

    BUILT_IN_GLOBALS_JS = [
      "setInterval",
      "setTimeout",
      "clearInterval",
      "clearTimeout",

      "require",
      "exports",

      "eval",
      "isFinite",
      "isNaN",
      "parseFloat",
      "parseInt",
      "decodeURI",
      "decodeURIComponent",
      "encodeURI",
      "encodeURIComponent",
      "escape",
      "unescape",
    ]

    BUILT_IN_VARIABLES_JS = [
      "arguments",
      "this",
      "super",
      "console",
      "window",
      "document",
      "localStorage",
      "sessionStorage",
      "module",
      "self",
      "global", # Node.js
    ]

    BUILT_INS_JS = BUILT_IN_GLOBALS_JS + TYPES_JS + ERROR_TYPES_JS

    # https://tc39.es/ecma262/#sec-literals-numeric-literals
    def self.number_mode : Mode
      decimal_digits = "[0-9](_?[0-9])*"
      frac = "\\.(#{decimal_digits})"
      # DecimalIntegerLiteral, including Annex B NonOctalDecimalIntegerLiteral
      # https://tc39.es/ecma262/#sec-additional-syntax-numeric-literals
      decimal_integer = "0|[1-9](_?[0-9])*|0[0-7]*[89][0-9]*"
      Mode.new.apply(
        class_name: "number",
        variants: [
          # DecimalLiteral
          Mode.new.apply(begin: "(\\b(#{decimal_integer})((#{frac})|\\.)?|(#{frac}))" +
                               "[eE][+-]?(#{decimal_digits})\\b"),
          Mode.new.apply(begin: "\\b(#{decimal_integer})\\b((#{frac})\\b|\\.)?|(#{frac})\\b"),

          # DecimalBigIntegerLiteral
          Mode.new.apply(begin: "\\b(0|[1-9](_?[0-9])*)n\\b"),

          # NonDecimalIntegerLiteral
          Mode.new.apply(begin: "\\b0[xX][0-9a-fA-F](_?[0-9a-fA-F])*n?\\b"),
          Mode.new.apply(begin: "\\b0[bB][0-1](_?[0-1])*n?\\b"),
          Mode.new.apply(begin: "\\b0[oO][0-7](_?[0-7])*n?\\b"),

          # LegacyOctalIntegerLiteral (does not include underscore separators)
          # https://tc39.es/ecma262/#sec-additional-syntax-numeric-literals
          Mode.new.apply(begin: "\\b0[0-7]+n?\\b"),
        ] of Mode,
        relevance: 0
      )
    end

    def self.keywords_js : Hash(String, KeywordsVal)
      kw = {} of String => KeywordsVal
      kw["$pattern"] = IDENT_RE_JS
      kw["keyword"] = KEYWORDS_JS
      kw["literal"] = LITERALS_JS
      kw["built_in"] = BUILT_INS_JS
      kw["variable.language"] = BUILT_IN_VARIABLES_JS
      kw
    end

    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      number = number_mode

      # Takes a string like "<Booger" and checks to see
      # if we can find a matching "</Booger" later in the content.
      has_closing_tag = ->(match : EnhancedMatch, after : Int32) {
        tag = "</" + match[0].not_nil![1..]
        pos = match.input.index(tag, after)
        !pos.nil?
      }

      fragment_begin = "<>"
      fragment_end = "</>"
      # to avoid some special cases inside isTrulyOpeningTag
      xml_self_closing = /<[A-Za-z0-9\\._:-]+\s*\/>/
      xml_tag_begin = /<[A-Za-z0-9\\._:-]+/
      xml_tag_end = /\/[A-Za-z0-9\\._:-]+>|\/>/
      is_truly_opening_tag = ->(match : EnhancedMatch, response : Response) {
        after_match_index = match.text.bytesize + match.index
        next_byte = match.input.byte_at?(after_match_index)
        # HTML should not include another raw `<` inside a tag
        # nested type? `<Array<Array<number>>`, etc.
        # the , gives away that this is not HTML: `<T, A extends keyof T, V>`
        if next_byte == '<'.ord || next_byte == ','.ord
          response.ignore_match
        else
          # `<something>`
          # Quite possibly a tag, lets look for a matching closing tag...
          if next_byte == '>'.ord
            # if we cannot find a matching closing tag, then we
            # will ignore it
            response.ignore_match unless has_closing_tag.call(match, after_match_index)
          end

          # `<blah />` (self-closing)
          # handled by simpleSelfClosing rule

          after_match = after_match_index < match.input.bytesize ? match.input.byte_slice(after_match_index) : ""

          # some more template typing stuff
          #  <T = any>(key?: string) => Modify<
          if /^\s*=/.matches?(after_match) ||
             # `<From extends string>`
             # technically this could be HTML, but it smells like a type
             # NOTE: This is ugh, but added specifically for https://github.com/highlightjs/highlight.js/issues/3276
             /^\s+extends\s+/.matches?(after_match)
            response.ignore_match
          end
        end
        nil
      }
      keywords = keywords_js

      subst = Mode.new.apply(
        class_name: "subst",
        begin: "\\$\\{",
        end: "\\}",
        keywords: keywords,
        contains: [] of Mode # defined later
      )
      html_template = Mode.new.apply(
        begin: ".?html`",
        end: "",
        starts: Mode.new.apply(
          end: "`",
          return_end: false,
          contains: [
            MODES::BACKSLASH_ESCAPE,
            subst,
          ] of Mode,
          sub_language: "xml"
        )
      )
      css_template = Mode.new.apply(
        begin: ".?css`",
        end: "",
        starts: Mode.new.apply(
          end: "`",
          return_end: false,
          contains: [
            MODES::BACKSLASH_ESCAPE,
            subst,
          ] of Mode,
          sub_language: "css"
        )
      )
      graphql_template = Mode.new.apply(
        begin: ".?gql`",
        end: "",
        starts: Mode.new.apply(
          end: "`",
          return_end: false,
          contains: [
            MODES::BACKSLASH_ESCAPE,
            subst,
          ] of Mode,
          sub_language: "graphql"
        )
      )
      template_string = Mode.new.apply(
        class_name: "string",
        begin: "`",
        end: "`",
        contains: [
          MODES::BACKSLASH_ESCAPE,
          subst,
        ] of Mode
      )
      jsdoc_comment = hljs.comment(
        /\/\*\*(?!\/)/,
        "\\*/",
        Mode.new.apply(
          relevance: 0,
          contains: [
            Mode.new.apply(
              begin: "(?=@[A-Za-z]+)",
              relevance: 0,
              contains: [
                Mode.new.apply(
                  class_name: "doctag",
                  begin: "@[A-Za-z]+"
                ),
                Mode.new.apply(
                  class_name: "type",
                  begin: "\\{",
                  end: "\\}",
                  exclude_end: true,
                  exclude_begin: true,
                  relevance: 0
                ),
                Mode.new.apply(
                  class_name: "variable",
                  begin: IDENT_RE_JS + "(?=\\s*(-)|$)",
                  ends_parent: true,
                  relevance: 0
                ),
                # eat spaces (not newlines) so we can find
                # types or variables
                Mode.new.apply(
                  begin: /(?=[^\n])\s/,
                  relevance: 0
                ),
              ] of Mode
            ),
          ] of Mode
        )
      )
      comment = Mode.new.apply(
        class_name: "comment",
        variants: [
          jsdoc_comment,
          MODES::C_BLOCK_COMMENT_MODE,
          MODES::C_LINE_COMMENT_MODE,
        ] of Mode
      )
      subst_internals = [
        MODES::APOS_STRING_MODE,
        MODES::QUOTE_STRING_MODE,
        html_template,
        css_template,
        graphql_template,
        template_string,
        # Skip numbers when they are part of a variable name
        Mode.new.apply(match: /\$\d+/),
        number,
        # This is intentional:
        # See https://github.com/highlightjs/highlight.js/issues/3288
        # hljs.REGEXP_MODE
      ] of Mode
      subst.contains = subst_internals + ([Mode.new.apply(
        # we need to pair up {} inside our subst to prevent
        # it from ending too early by matching another }
        begin: /\{/,
        end: /\}/,
        keywords: keywords,
        contains: ([Mode.self_marker] of Mode) + subst_internals
      )] of Mode)
      subst_and_comments = comment.variants.not_nil! + subst.contains.not_nil!
      params_contains = subst_and_comments + ([Mode.new.apply(
        # eat recursive parens in sub expressions
        begin: /(\s*)\(/,
        end: /\)/,
        keywords: keywords,
        contains: ([Mode.self_marker] of Mode) + subst_and_comments
      )] of Mode)
      params = Mode.new.apply(
        class_name: "params",
        # convert this to negative lookbehind in v12
        begin: /(\s*)\(/, # to match the parms with
        end: /\)/,
        exclude_begin: true,
        exclude_end: true,
        keywords: keywords,
        contains: params_contains
      )

      # ES6 classes
      class_or_extends = Mode.new.apply(
        variants: [
          # class Car extends vehicle
          Mode.new.apply(
            match: [
              /class/,
              /\s+/,
              IDENT_RE_JS,
              /\s+/,
              /extends/,
              /\s+/,
              regex.concat(IDENT_RE_JS, "(", regex.concat(/\./, IDENT_RE_JS), ")*"),
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
              "5" => "keyword",
              "7" => "title.class.inherited",
            }
          ),
          # class Car
          Mode.new.apply(
            match: [
              /class/,
              /\s+/,
              IDENT_RE_JS,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "title.class",
            }
          ),
        ] of Mode
      )

      class_reference = Mode.new.apply(
        relevance: 0,
        match: regex.either([
          # Hard coded exceptions
          /\bJSON/,
          # Float32Array, OutT
          /\b[A-Z][a-z]+([A-Z][a-z]*|\d)*/,
          # CSSFactory, CSSFactoryT
          /\b[A-Z]{2,}([A-Z][a-z]+|\d)+([A-Z][a-z]*)*/,
          # FPs, FPsT
          /\b[A-Z]{2,}[a-z]+([A-Z][a-z]+|\d)*([A-Z][a-z]*)*/,
          # P
          # single letters are not highlighted
          # BLAH
          # this will be flagged as a UPPER_CASE_CONSTANT instead
        ] of String | Regex),
        class_name: "title.class",
        keywords: {
          # se we still get relevance credit for JS library classes
          "_" => TYPES_JS + ERROR_TYPES_JS,
        } of String => KeywordsVal
      )

      use_strict = Mode.new.apply(
        label: "use_strict",
        class_name: "meta",
        relevance: 10,
        begin: /^\s*['"]use (strict|asm)['"]/
      )

      function_definition = Mode.new.apply(
        variants: [
          Mode.new.apply(
            match: [
              /function/,
              /\s+/,
              IDENT_RE_JS,
              /(?=\s*\()/,
            ] of String | Regex
          ),
          # anonymous function
          Mode.new.apply(
            match: [
              /function/,
              /\s*(?=\()/,
            ] of String | Regex
          ),
        ] of Mode,
        class_name: nil,
        scope: {
          "1" => "keyword",
          "3" => "title.function",
        },
        label: "func.def",
        contains: [params] of Mode,
        illegal: /%/
      )
      # className: {1, 3} — multi-class через scope, class_name не нужен
      function_definition.class_name = nil

      upper_case_constant = Mode.new.apply(
        relevance: 0,
        match: /\b[A-Z][A-Z_0-9]+\b/,
        class_name: "variable.constant"
      )

      none_of = ->(list : Array(String)) {
        regex.concat("(?!", list.join("|"), ")")
      }

      function_call = Mode.new.apply(
        match: regex.concat(
          /\b/,
          none_of.call((BUILT_IN_GLOBALS_JS + ["super", "import", "await"]).map { |x| "#{x}\\s*\\(" }),
          IDENT_RE_JS, regex.lookahead(/\s*\(/)),
        class_name: "title.function",
        relevance: 0
      )

      property_access = Mode.new.apply(
        begin: regex.concat(/\./, regex.lookahead(
          regex.concat(IDENT_RE_JS, /(?![0-9A-Za-z$_(])/)
        )),
        end: IDENT_RE_JS,
        exclude_begin: true,
        keywords: "prototype",
        class_name: "property",
        relevance: 0
      )

      getter_or_setter = Mode.new.apply(
        match: [
          /get|set/,
          /\s+/,
          IDENT_RE_JS,
          /(?=\()/,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "title.function",
        },
        contains: [
          # eat to avoid empty params
          Mode.new.apply(begin: /\(\)/),
          params,
        ] of Mode
      )

      func_lead_in_re = "(\\(" +
                         "[^()]*(\\(" +
                         "[^()]*(\\(" +
                         "[^()]*" +
                         "\\)[^()]*)*" +
                         "\\)[^()]*)*" +
                         "\\)|" + UNDERSCORE_IDENT_RE + ")\\s*=>"

      function_variable = Mode.new.apply(
        match: [
          /const|var|let/, /\s+/,
          IDENT_RE_JS, /\s*/,
          /=\s*/,
          /(async\s*)?/, # async is optional
          regex.lookahead(func_lead_in_re),
        ] of String | Regex,
        keywords: "async",
        scope: {
          "1" => "keyword",
          "3" => "title.function",
        },
        contains: [
          params,
        ] of Mode
      )

      mode = Mode.new.apply(
        name: "JavaScript",
        aliases: ["js", "jsx", "mjs", "cjs"],
        keywords: keywords,
        # this will be extended by TypeScript
        illegal: /#(?![$_A-Za-z])/,
        contains: [
          hljs.shebang(
            label: "shebang",
            binary: "node",
            relevance: 5
          ),
          use_strict,
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
          html_template,
          css_template,
          graphql_template,
          template_string,
          comment,
          # Skip numbers when they are part of a variable name
          Mode.new.apply(match: /\$\d+/),
          number,
          class_reference,
          Mode.new.apply(
            scope: "attr",
            match: IDENT_RE_JS + regex.lookahead(":"),
            relevance: 0
          ),
          function_variable,
          # "value" container
          Mode.new.apply(
            begin: "(" + RE_STARTERS_RE + "|\\b(case|return|throw)\\b)\\s*",
            keywords: "return throw case",
            relevance: 0,
            contains: [
              comment,
              MODES::REGEXP_MODE,
              Mode.new.apply(
                class_name: "function",
                # we have to count the parens to make sure we actually have the
                # correct bounding ( ) before the =>.  There could be any number of
                # sub-expressions inside also surrounded by parens.
                begin: func_lead_in_re,
                return_begin: true,
                end: "\\s*=>",
                contains: [
                  Mode.new.apply(
                    class_name: "params",
                    variants: [
                      Mode.new.apply(
                        begin: UNDERSCORE_IDENT_RE,
                        relevance: 0
                      ),
                      Mode.new.apply(
                        class_name: "",
                        begin: /\(\s*\)/,
                        skip: true
                      ),
                      Mode.new.apply(
                        begin: /(\s*)\(/,
                        end: /\)/,
                        exclude_begin: true,
                        exclude_end: true,
                        keywords: keywords,
                        contains: params_contains
                      ),
                    ] of Mode
                  ),
                ] of Mode
              ),
              # could be a comma delimited list of params to a function call
              Mode.new.apply(
                begin: /,/,
                relevance: 0
              ),
              Mode.new.apply(
                match: /\s+/,
                relevance: 0
              ),
              # JSX
              Mode.new.apply(
                variants: [
                  Mode.new.apply(begin: fragment_begin, end: fragment_end),
                  Mode.new.apply(match: xml_self_closing),
                  Mode.new.apply(
                    begin: xml_tag_begin,
                    # we carefully check the opening tag to see if it truly
                    # is a tag and not a false positive
                    on_begin: is_truly_opening_tag,
                    end: xml_tag_end
                  ),
                ] of Mode,
                sub_language: "xml",
                contains: [
                  Mode.new.apply(
                    begin: xml_tag_begin,
                    end: xml_tag_end,
                    skip: true,
                    contains: [Mode.self_marker] of Mode
                  ),
                ] of Mode
              ),
            ] of Mode
          ),
          function_definition,
          # prevent this from getting swallowed up by function
          # since they appear "function like"
          Mode.new.apply(begin_keywords: "while if switch catch for"),
          Mode.new.apply(
            # we have to count the parens to make sure we actually have the correct
            # bounding ( ).  There could be any number of sub-expressions inside
            # also surrounded by parens.
            begin: "\\b(?!function)" + UNDERSCORE_IDENT_RE +
                   "\\(" + # first parens
                   "[^()]*(\\(" +
                   "[^()]*(\\(" +
                   "[^()]*" +
                   "\\)[^()]*)*" +
                   "\\)[^()]*)*" +
                   "\\)\\s*\\{", # end parens
            return_begin: true,
            label: "func.def",
            contains: [
              params,
              MODES::TITLE_MODE.inherit(Mode.new.apply(begin: IDENT_RE_JS, class_name: "title.function")),
            ] of Mode
          ),
          # catch ... so it won't trigger the property rule below
          Mode.new.apply(
            match: /\.\.\./,
            relevance: 0
          ),
          property_access,
          # hack: prevents detection of keywords in some circumstances
          # .keyword()
          # $keyword = x
          Mode.new.apply(
            match: "\\$" + IDENT_RE_JS,
            relevance: 0
          ),
          Mode.new.apply(
            match: [/\bconstructor(?=\s*\()/] of String | Regex,
            scope: {"1" => "title.function"},
            contains: [params] of Mode
          ),
          function_call,
          upper_case_constant,
          class_or_extends,
          getter_or_setter,
          Mode.new.apply(
            match: /\$[(.]/ # relevance booster for a pattern common to JS libs: `$(something)` and `$.something`
          ),
        ] of Mode
      )
      exports = {} of String => Mode | KeywordsVal | Array(Mode)
      exports["PARAMS_CONTAINS"] = params_contains
      exports["CLASS_REFERENCE"] = class_reference
      mode.exports = exports
      mode
    end
  end

  Languages.register("javascript", ->(hljs : HLJS) { JavascriptLang.defined(hljs) })
end
