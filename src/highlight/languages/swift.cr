# Порт lib/languages/swift.js (highlight.js 11.12.0).
# Списки извлечены из оригинала скриптом spec/gen_swift_lists.js.

module Highlight::Languages
  module Swift
    DOT_KEYWORDS_RAW = %w[Protocol Type]
    OPTIONAL_DOT_KEYWORDS_RAW = %w[init self]
    KEYWORD_TYPES = %w[Any Self]
    KEYWORDS_MIXED = [
      "actor",
      "any",
      "associatedtype",
      "async",
      "await",
      /as\?/,
      /as!/,
      "as",
      "borrowing",
      "break",
      "case",
      "catch",
      "class",
      "consume",
      "consuming",
      "continue",
      "convenience",
      "copy",
      "default",
      "defer",
      "deinit",
      "didSet",
      "distributed",
      "do",
      "dynamic",
      "each",
      "else",
      "enum",
      "extension",
      "fallthrough",
      /fileprivate\(set\)/,
      "fileprivate",
      "final",
      "for",
      "func",
      "get",
      "guard",
      "if",
      "import",
      "indirect",
      "infix",
      /init\?/,
      /init!/,
      "inout",
      /internal\(set\)/,
      "internal",
      "in",
      "is",
      "isolated",
      "nonisolated",
      "lazy",
      "let",
      "macro",
      "mutating",
      "nonmutating",
      /open\(set\)/,
      "open",
      "operator",
      "optional",
      "override",
      "package",
      "postfix",
      "precedencegroup",
      "prefix",
      /private\(set\)/,
      "private",
      "protocol",
      /public\(set\)/,
      "public",
      "repeat",
      "required",
      "rethrows",
      "return",
      "set",
      "some",
      "static",
      "struct",
      "subscript",
      "super",
      "switch",
      "throws",
      "throw",
      /try\?/,
      /try!/,
      "try",
      "typealias",
      /unowned\(safe\)/,
      /unowned\(unsafe\)/,
      "unowned",
      "var",
      "weak",
      "where",
      "while",
      "willSet",
    ] of String | Regex
    LITERALS = %w[false nil true]
    PRECEDENCEGROUP_KEYWORDS = %w[assignment associativity higherThan left lowerThan none right]
    NUMBER_SIGN_KEYWORDS = %w[#colorLiteral #column #dsohandle #else #elseif #endif #error #file #fileID #fileLiteral #filePath #function #if #imageLiteral #keyPath #line #selector #sourceLocation #warning]
    BUILT_INS = %w[abs all any assert assertionFailure debugPrint dump fatalError getVaList isKnownUniquelyReferenced max min numericCast pointwiseMax pointwiseMin precondition preconditionFailure print readLine repeatElement sequence stride swap swift_unboxFromSwiftValueWithType transcode type unsafeBitCast unsafeDowncast withExtendedLifetime withUnsafeMutablePointer withUnsafePointer withVaList withoutActuallyEscaping zip]
    KEYWORD_ATTRIBUTES = [
      "attached",
      "autoclosure",
      "convention\\((?:swift|block|c)\\",
      "dynamicCallable",
      "dynamicMemberLookup",
      "escaping",
      "freestanding",
      "frozen",
      "GKInspectable",
      "IBAction",
      "IBDesignable",
      "IBInspectable",
      "IBOutlet",
      "IBSegueAction",
      "inlinable",
      "main",
      "nonobjc",
      "NSApplicationMain",
      "NSCopying",
      "NSManaged",
      "objc\\(" + IDENTIFIER + "\\)",
      "objcMembers",
      "propertyWrapper",
      "requires_stored_property_inits",
      "resultBuilder",
      "Sendable",
      "testable",
      "UIApplicationMain",
      "unchecked",
      "unknown",
      "usableFromInline",
      "warn_unqualified_access",
    ] of String | Regex
    AVAILABILITY_KEYWORDS = %w[iOS iOSApplicationExtension macOS macOSApplicationExtension macCatalyst macCatalystApplicationExtension watchOS watchOSApplicationExtension tvOS tvOSApplicationExtension swift]

    OPERATOR_HEAD = RegexHelpers.either([
      "[/=\\-+!*%<>&|^~?]",
      "[\\u00A1-\\u00A7]",
      "[\\u00A9\\u00AB]",
      "[\\u00AC\\u00AE]",
      "[\\u00B0\\u00B1]",
      "[\\u00B6\\u00BB\\u00BF\\u00D7\\u00F7]",
      "[\\u2016-\\u2017]",
      "[\\u2020-\\u2027]",
      "[\\u2030-\\u203E]",
      "[\\u2041-\\u2053]",
      "[\\u2055-\\u205E]",
      "[\\u2190-\\u23FF]",
      "[\\u2500-\\u2775]",
      "[\\u2794-\\u2BFF]",
      "[\\u2E00-\\u2E7F]",
      "[\\u3001-\\u3003]",
      "[\\u3008-\\u3020]",
      "[\\u3030]",
    ] of String)

    OPERATOR_CHARACTER = RegexHelpers.either([
      OPERATOR_HEAD,
      "[\\u0300-\\u036F]",
      "[\\u1DC0-\\u1DFF]",
      "[\\u20D0-\\u20FF]",
      "[\\uFE00-\\uFE0F]",
      "[\\uFE20-\\uFE2F]",
    ] of String)

    OPERATOR = RegexHelpers.concat(OPERATOR_HEAD, OPERATOR_CHARACTER, "*")

    IDENTIFIER_HEAD = RegexHelpers.either([
      "[a-zA-Z_]",
      "[\\u00A8\\u00AA\\u00AD\\u00AF\\u00B2-\\u00B5\\u00B7-\\u00BA]",
      "[\\u00BC-\\u00BE\\u00C0-\\u00D6\\u00D8-\\u00F6\\u00F8-\\u00FF]",
      "[\\u0100-\\u02FF\\u0370-\\u167F\\u1681-\\u180D\\u180F-\\u1DBF]",
      "[\\u1E00-\\u1FFF]",
      "[\\u200B-\\u200D\\u202A-\\u202E\\u203F-\\u2040\\u2054\\u2060-\\u206F]",
      "[\\u2070-\\u20CF\\u2100-\\u218F\\u2460-\\u24FF\\u2776-\\u2793]",
      "[\\u2C00-\\u2DFF\\u2E80-\\u2FFF]",
      "[\\u3004-\\u3007\\u3021-\\u302F\\u3031-\\u303F\\u3040-\\uD7FF]",
      "[\\uF900-\\uFD3D\\uFD40-\\uFDCF\\uFDF0-\\uFE1F\\uFE30-\\uFE44]",
      "[\\uFE47-\\uFEFE\\uFF00-\\uFFFD]",
    ] of String)

    IDENTIFIER_CHARACTER = RegexHelpers.either([
      IDENTIFIER_HEAD,
      "\\d",
      "[\\u0300-\\u036F\\u1DC0-\\u1DFF\\u20D0-\\u20FF\\uFE20-\\uFE2F]",
    ] of String)

    IDENTIFIER = RegexHelpers.concat(IDENTIFIER_HEAD, IDENTIFIER_CHARACTER, "*")
    TYPE_IDENTIFIER = RegexHelpers.concat(/[A-Z]/, IDENTIFIER_CHARACTER, "*")

    REGEXP_CONTENTS = [
      MODES::BACKSLASH_ESCAPE,
      Mode.new.apply(
        begin: /\[/,
        end: /\]/,
        relevance: 0,
        contains: [MODES::BACKSLASH_ESCAPE] of Mode
      ),
    ] of Mode

    # JS keywordWrapper: для RegExp-объектов String(re) кончается на "/",
    # поэтому всегда \B; для строк — \b при словесном конце.
    def self.keyword_wrapper(kw : String | Regex) : String
      tail = kw.is_a?(Regex) ? "\\B" : (kw =~ /\w$/ ? "\\b" : "\\B")
      RegexHelpers.concat(/\b/, kw, tail)
    end

    def self.escaped_character(raw_delimiter : String = "") : Mode
      Mode.new.apply(
        class_name: "subst",
        variants: [
          Mode.new.apply(match: RegexHelpers.concat(/\\/, raw_delimiter, /[0\\tnr"']/)),
          Mode.new.apply(match: RegexHelpers.concat(/\\/, raw_delimiter, /u\{[0-9a-fA-F]{1,8}\}/)),
        ] of Mode
      )
    end

    def self.escaped_newline(raw_delimiter : String = "") : Mode
      Mode.new.apply(
        class_name: "subst",
        match: RegexHelpers.concat(/\\/, raw_delimiter, /[\t ]*(?:[\r\n]|\r\n)/)
      )
    end

    def self.interpolation(raw_delimiter : String = "") : Mode
      Mode.new.apply(
        class_name: "subst",
        label: "interpol",
        begin: RegexHelpers.concat(/\\/, raw_delimiter, /\(/),
        end: /\)/
      )
    end

    def self.multiline_string(raw_delimiter : String = "") : Mode
      Mode.new.apply(
        begin: RegexHelpers.concat(raw_delimiter, /"""/),
        end: RegexHelpers.concat(/"""/, raw_delimiter),
        contains: [
          escaped_character(raw_delimiter),
          escaped_newline(raw_delimiter),
          interpolation(raw_delimiter),
        ] of Mode
      )
    end

    def self.single_line_string(raw_delimiter : String = "") : Mode
      Mode.new.apply(
        begin: RegexHelpers.concat(raw_delimiter, /"/),
        end: RegexHelpers.concat(/"/, raw_delimiter),
        contains: [
          escaped_character(raw_delimiter),
          interpolation(raw_delimiter),
        ] of Mode
      )
    end

    def self.extended_regexp_literal(raw_delimiter : String) : Mode
      begin_p = RegexHelpers.concat(raw_delimiter, /\//)
      end_p = RegexHelpers.concat(/\//, raw_delimiter)
      Mode.new.apply(
        begin: begin_p,
        end: end_p,
        contains: REGEXP_CONTENTS + [Mode.new.apply(
          scope: "comment",
          begin: "#(?!.*" + end_p + ")",
          end: /$/,
        )] of Mode
      )
    end

    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers

      whitespace = Mode.new.apply(
        match: /\s+/,
        relevance: 0
      )
      # https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#ID411
      block_comment = hljs.comment("/\\*", "\\*/", Mode.new.apply(
        contains: [Mode.self_marker] of Mode
      ))
      comments = [
        MODES::C_LINE_COMMENT_MODE,
        block_comment,
      ] of Mode

      optional_dot_wrapped = OPTIONAL_DOT_KEYWORDS_RAW.map { |kw| keyword_wrapper(kw) }

      # https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#ID413
      # https://docs.swift.org/swift-book/ReferenceManual/zzSummaryOfTheGrammar.html
      dot_keyword = Mode.new.apply(
        match: [/\./, RegexHelpers.either(
          DOT_KEYWORDS_RAW.map { |kw| keyword_wrapper(kw) } + optional_dot_wrapped
        )] of String | Regex,
        scope: {"2" => "keyword"}
      )
      # Consume .keyword to prevent highlighting properties and methods as keywords.
      keyword_guard = Mode.new.apply(
        match: RegexHelpers.concat(/\./, RegexHelpers.either(KEYWORDS_MIXED)),
        relevance: 0
      )
      plain_keywords = KEYWORDS_MIXED.select(String).map(&.as(String)) + ["_|0"] # seems common, so 0 relevance
      regex_keywords = (KEYWORDS_MIXED.select(Regex).map(&.as(Regex)) + KEYWORD_TYPES).map { |kw| keyword_wrapper(kw) }
      keyword_mode = Mode.new.apply(
        variants: [
          Mode.new.apply(
            class_name: "keyword",
            match: RegexHelpers.either(regex_keywords + optional_dot_wrapped)
          ),
        ] of Mode
      )
      # find all the regular keywords
      keywords_hash = {
        "$pattern" => RegexHelpers.either([/\b\w+/, /#\w+/] of Regex), # regular keywords, number keywords
        "keyword"  => plain_keywords + NUMBER_SIGN_KEYWORDS,
        "literal"  => LITERALS,
      } of String => KeywordsVal
      keyword_modes = [
        dot_keyword,
        keyword_guard,
        keyword_mode,
      ] of Mode

      # https://github.com/apple/swift/tree/main/stdlib/public/core
      # Consume .built_in to prevent highlighting properties and methods.
      built_in_guard = Mode.new.apply(
        match: RegexHelpers.concat(/\./, RegexHelpers.either(BUILT_INS)),
        relevance: 0
      )
      built_in_mode = Mode.new.apply(
        class_name: "built_in",
        match: RegexHelpers.concat(/\b/, RegexHelpers.either(BUILT_INS), /(?=\()/)
      )
      built_ins_modes = [
        built_in_guard,
        built_in_mode,
      ] of Mode

      # https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#ID418
      # Prevent -> from being highlighting as an operator.
      operator_guard = Mode.new.apply(
        match: /->/,
        relevance: 0
      )
      operator_mode = Mode.new.apply(
        class_name: "operator",
        relevance: 0,
        variants: [
          Mode.new.apply(match: OPERATOR),
          # dot-operator: only operators that start with a dot are allowed to use dots as
          # characters (..., ...<, .*, etc). So there rule here is: a dot followed by one or more
          # characters that may also include dots.
          Mode.new.apply(match: "\\.(\\.|" + OPERATOR_CHARACTER + ")+"),
        ] of Mode
      )
      operators_modes = [
        operator_guard,
        operator_mode,
      ] of Mode

      # https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#grammar_numeric-literal
      # TODO: Update for leading `-` after lookbehind is supported everywhere
      decimal_digits = "([0-9]_*)+"
      hex_digits = "([0-9a-fA-F]_*)+"
      number_mode = Mode.new.apply(
        class_name: "number",
        relevance: 0,
        variants: [
          # decimal floating-point-literal (subsumes decimal-literal)
          Mode.new.apply(match: "\\b(" + decimal_digits + ")(\\.(" + decimal_digits + "))?" +
            "([eE][+-]?(" + decimal_digits + "))?\\b"),
          # hexadecimal floating-point-literal (subsumes hexadecimal-literal)
          Mode.new.apply(match: "\\b0x(" + hex_digits + ")(\\.(" + hex_digits + "))?" +
            "([pP][+-]?(" + decimal_digits + "))?\\b"),
          # octal-literal
          Mode.new.apply(match: /\b0o([0-7]_*)+\b/),
          # binary-literal
          Mode.new.apply(match: /\b0b([01]_*)+\b/),
        ] of Mode
      )

      # https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#grammar_string-literal
      string_mode = Mode.new.apply(
        class_name: "string",
        variants: [
          multiline_string,
          multiline_string("#"),
          multiline_string("##"),
          multiline_string("###"),
          single_line_string,
          single_line_string("#"),
          single_line_string("##"),
          single_line_string("###"),
        ] of Mode
      )

      bare_regexp_literal = Mode.new.apply(
        begin: "\\/[^\\s](?=[^/\\n]*\\/)",
        end: /\//,
        contains: REGEXP_CONTENTS
      )

      # https://docs.swift.org/swift-book/documentation/the-swift-programming-language/lexicalstructure/#Regular-Expression-Literals
      regexp_mode = Mode.new.apply(
        scope: "regexp",
        variants: [
          extended_regexp_literal("###"),
          extended_regexp_literal("##"),
          extended_regexp_literal("#"),
          bare_regexp_literal,
        ] of Mode
      )

      # https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html#ID412
      quoted_identifier = Mode.new.apply(
        match: RegexHelpers.concat(/`/, IDENTIFIER, /`/)
      )
      implicit_parameter = Mode.new.apply(
        class_name: "variable",
        match: /\$\d+/
      )
      property_wrapper_projection = Mode.new.apply(
        class_name: "variable",
        match: "\\$" + IDENTIFIER_CHARACTER + "+"
      )
      identifiers = [
        quoted_identifier,
        implicit_parameter,
        property_wrapper_projection,
      ] of Mode

      # https://docs.swift.org/swift-book/ReferenceManual/Attributes.html
      available_attribute = Mode.new.apply(
        match: "(@|#(un)?)available",
        scope: "keyword",
        starts: Mode.new.apply(
          contains: [
            Mode.new.apply(
              begin: /\(/,
              end: /\)/,
              keywords: AVAILABILITY_KEYWORDS,
              contains: operators_modes + [number_mode, string_mode] of Mode
            ),
          ] of Mode
        )
      )

      keyword_attribute = Mode.new.apply(
        scope: "keyword",
        match: RegexHelpers.concat(/@/, RegexHelpers.either(KEYWORD_ATTRIBUTES),
          regex.lookahead(RegexHelpers.either([/\(/, /\s+/] of Regex))),
      )

      user_defined_attribute = Mode.new.apply(
        scope: "meta",
        match: RegexHelpers.concat(/@/, IDENTIFIER)
      )

      attributes = [
        available_attribute,
        keyword_attribute,
        user_defined_attribute,
      ] of Mode

      # https://docs.swift.org/swift-book/ReferenceManual/Types.html
      type_contains = [
        # Common Apple frameworks, for relevance boost
        Mode.new.apply(
          class_name: "type",
          match: RegexHelpers.concat(/(AV|CA|CF|CG|CI|CL|CM|CN|CT|MK|MP|MTK|MTL|NS|SCN|SK|UI|WK|XC)/, IDENTIFIER_CHARACTER, "+")
        ),
        # Type identifier
        Mode.new.apply(
          class_name: "type",
          match: TYPE_IDENTIFIER,
          relevance: 0
        ),
        # Optional type
        Mode.new.apply(
          match: /[?!]+/,
          relevance: 0
        ),
        # Variadic parameter
        Mode.new.apply(
          match: /\.\.\./,
          relevance: 0
        ),
        # Protocol composition
        Mode.new.apply(
          match: RegexHelpers.concat(/\s+&\s+/, regex.lookahead(TYPE_IDENTIFIER)),
          relevance: 0
        ),
      ] of Mode
      type_mode = Mode.new.apply(
        match: regex.lookahead(/\b[A-Z]/),
        relevance: 0,
        contains: type_contains
      )
      generic_arguments = Mode.new.apply(
        begin: /</,
        end: />/,
        keywords: keywords_hash,
        contains: comments + keyword_modes + attributes + [operator_guard, type_mode] of Mode
      )
      type_contains << generic_arguments

      # https://docs.swift.org/swift-book/ReferenceManual/Expressions.html#ID552
      # Prevents element names from being highlighted as keywords.
      tuple_element_name = Mode.new.apply(
        match: RegexHelpers.concat(IDENTIFIER, /\s*:/),
        keywords: "_|0",
        relevance: 0
      )
      # Matches tuples as well as the parameter list of a function type.
      tuple = Mode.new.apply(
        begin: /\(/,
        end: /\)/,
        relevance: 0,
        keywords: keywords_hash,
        contains: [
          Mode.self_marker,
          tuple_element_name,
        ] of Mode + comments + [regexp_mode] of Mode +
          keyword_modes + built_ins_modes + operators_modes +
          [number_mode, string_mode] of Mode + identifiers + attributes + [type_mode] of Mode
      )

      generic_parameters = Mode.new.apply(
        begin: /</,
        end: />/,
        keywords: "repeat each",
        contains: comments + [type_mode] of Mode
      )
      function_parameter_name = Mode.new.apply(
        begin: RegexHelpers.either([
          regex.lookahead(RegexHelpers.concat(IDENTIFIER, /\s*:/)),
          regex.lookahead(RegexHelpers.concat(IDENTIFIER, /\s+/, IDENTIFIER, /\s*:/)),
        ] of String),
        end: /:/,
        relevance: 0,
        contains: [
          Mode.new.apply(
            class_name: "keyword",
            match: /\b_\b/
          ),
          Mode.new.apply(
            class_name: "params",
            match: IDENTIFIER
          ),
        ] of Mode
      )
      function_parameters = Mode.new.apply(
        begin: /\(/,
        end: /\)/,
        keywords: keywords_hash,
        contains: [function_parameter_name] of Mode + comments + keyword_modes +
          operators_modes + [number_mode, string_mode] of Mode + attributes +
          [type_mode, tuple] of Mode,
        ends_parent: true,
        illegal: /["']/
      )
      # https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID362
      # https://docs.swift.org/swift-book/documentation/the-swift-programming-language/declarations/#Macro-Declaration
      function_or_macro = Mode.new.apply(
        match: [
          /(func|macro)/,
          /\s+/,
          RegexHelpers.either([
            RegexHelpers.concat(/`/, IDENTIFIER, /`/),
            IDENTIFIER,
            OPERATOR,
          ] of String),
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "title.function",
        },
        contains: [
          generic_parameters,
          function_parameters,
          whitespace,
        ] of Mode,
        illegal: [/\[/, /%/] of String | Regex
      )

      # https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID375
      # https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID379
      init_subscript = Mode.new.apply(
        match: [
          /\b(?:subscript|init[?!]?)\b/,
          /\s*(?=[<(])/,
        ] of String | Regex,
        scope: {"1" => "keyword"},
        contains: [
          generic_parameters,
          function_parameters,
          whitespace,
        ] of Mode,
        illegal: /\[|%/
      )
      # https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID380
      operator_declaration = Mode.new.apply(
        match: [
          /operator/,
          /\s+/,
          OPERATOR,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "title",
        }
      )

      # https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID550
      precedencegroup = Mode.new.apply(
        begin: [
          /precedencegroup/,
          /\s+/,
          TYPE_IDENTIFIER,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "title",
        },
        contains: [type_mode] of Mode,
        keywords: PRECEDENCEGROUP_KEYWORDS + LITERALS,
        end: /}/
      )

      class_func_declaration = Mode.new.apply(
        match: [
          /class\b/,
          /\s+/,
          /func\b/,
          /\s+/,
          /\b[A-Za-z_][A-Za-z0-9_]*\b/,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "keyword",
          "5" => "title.function",
        }
      )

      class_var_declaration = Mode.new.apply(
        match: [
          /class\b/,
          /\s+/,
          /var\b/,
        ] of String | Regex,
        scope: {
          "1" => "keyword",
          "3" => "keyword",
        }
      )

      type_declaration = Mode.new.apply(
        begin: [
          /(struct|protocol|class|extension|enum|actor)/,
          /\s+/,
          IDENTIFIER,
          /\s*/,
        ] of String | Regex,
        begin_scope: {
          "1" => "keyword",
          "3" => "title.class",
        },
        keywords: keywords_hash,
        contains: [generic_parameters] of Mode + keyword_modes + [
          Mode.new.apply(
            begin: /:/,
            end: /\{/,
            keywords: keywords_hash,
            contains: [
              Mode.new.apply(
                scope: "title.class.inherited",
                match: TYPE_IDENTIFIER,
              ),
            ] of Mode + keyword_modes,
            relevance: 0,
          ),
        ] of Mode
      )

      # Add supported submodes to string interpolation.
      string_mode.variants.not_nil!.each do |variant|
        interpolation_mode = variant.contains.not_nil!.find { |m| m.label == "interpol" }.not_nil!
        # TODO: Interpolation can contain any expression, so there's room for improvement here.
        interpolation_mode.keywords = keywords_hash
        submodes = keyword_modes + built_ins_modes + operators_modes +
          [number_mode, string_mode] of Mode + identifiers
        interpolation_mode.contains = submodes + [
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            contains: [Mode.self_marker] of Mode + submodes
          ),
        ] of Mode
      end

      Mode.new.apply(
        name: "Swift",
        keywords: keywords_hash,
        contains: comments + [
          function_or_macro,
          init_subscript,
          class_func_declaration,
          class_var_declaration,
          type_declaration,
          operator_declaration,
          precedencegroup,
          Mode.new.apply(
            begin_keywords: "import",
            end: /$/,
            contains: comments,
            relevance: 0
          ),
          regexp_mode,
        ] of Mode + keyword_modes + built_ins_modes + operators_modes +
          [number_mode, string_mode] of Mode + identifiers + attributes +
          [type_mode, tuple] of Mode
      )
    end
  end

  Languages.register("swift", ->(hljs : HLJS) { Swift.defined(hljs) })
end
