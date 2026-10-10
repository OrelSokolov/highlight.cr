# Порт lib/languages/php.js (highlight.js 11.12.0).

module Highlight::Languages
  module Php
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # negative look-ahead tries to avoid matching patterns that are not
      # Perl at all like $ident$, @ident@, etc.
      not_perl_etc = /(?![A-Za-z0-9])(?![$])/
      ident_re = regex.concat(
        /[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*/,
        not_perl_etc)
      # Will not detect camelCase classes
      pascal_case_class_name_re = regex.concat(
        /(\\?[A-Z][a-z0-9_\x7f-\xff]+|\\?[A-Z]+(?=[A-Z][a-z0-9_\x7f-\xff])){1,}/,
        not_perl_etc)
      upcase_name_re = regex.concat(
        /[A-Z]+/,
        not_perl_etc)
      variable = Mode.new.apply(
        scope: "variable",
        match: "\\$+" + ident_re,
      )
      preprocessor = Mode.new.apply(
        scope: "meta",
        variants: [
          Mode.new.apply(begin: /<\?php/, relevance: 10), # boost for obvious PHP
          Mode.new.apply(begin: /<\?=/),
          # less relevant per PSR-1 which says not to use short-tags
          Mode.new.apply(begin: /<\?/, relevance: 0.1),
          Mode.new.apply(begin: /\?>/), # end php tag
        ] of Mode
      )
      subst = Mode.new.apply(
        scope: "subst",
        variants: [
          Mode.new.apply(begin: /\$\w+/),
          Mode.new.apply(
            begin: /\{\$/,
            end: /\}/
          ),
        ] of Mode
      )
      single_quoted = MODES::APOS_STRING_MODE.inherit
      single_quoted.illegal = nil
      double_quoted = MODES::QUOTE_STRING_MODE.inherit
      double_quoted.illegal = nil
      double_quoted.contains = MODES::QUOTE_STRING_MODE.contains.not_nil! + ([subst] of Mode)

      heredoc = Mode.new.apply(
        begin: /<<<[ \t]*(?:(\w+)|"(\w+)")\n/,
        end: /[ \t]*(\w+)\b/,
        contains: MODES::QUOTE_STRING_MODE.contains.not_nil! + ([subst] of Mode),
        on_begin: ->(m : EnhancedMatch, resp : Response) {
          resp.data["_beginMatch"] = (m[1] || m[2]).to_s
          nil
        },
        on_end: ->(m : EnhancedMatch, resp : Response) {
          resp.ignore_match if resp.data["_beginMatch"]? != m[1]
          nil
        }
      )

      nowdoc = hljs.end_same_as_begin(Mode.new.apply(
        begin: /<<<[ \t]*'(\w+)'\n/,
        end: /[ \t]*(\w+)\b/,
      ))
      # list of valid whitespaces because non-breaking space might be part of a IDENT_RE
      whitespace = "[ \\t\\n]"
      string_mode = Mode.new.apply(
        scope: "string",
        variants: [
          double_quoted,
          single_quoted,
          heredoc,
          nowdoc,
        ] of Mode
      )
      number = Mode.new.apply(
        scope: "number",
        variants: [
          Mode.new.apply(begin: "\\b0[bB][01]+(?:_[01]+)*\\b"), # Binary w/ underscore support
          Mode.new.apply(begin: "\\b0[oO][0-7]+(?:_[0-7]+)*\\b"), # Octals w/ underscore support
          Mode.new.apply(begin: "\\b0[xX][\\da-fA-F]+(?:_[\\da-fA-F]+)*\\b"), # Hex w/ underscore support
          # Decimals w/ underscore support, with optional fragments and scientific exponent (e) suffix.
          Mode.new.apply(begin: "(?:\\b\\d+(?:_\\d+)*(\\.(?:\\d+(?:_\\d+)*))?|\\B\\.\\d+)(?:[eE][+-]?\\d+)?"),
        ] of Mode,
        relevance: 0
      )
      literals = [
        "false",
        "null",
        "true",
      ]
      kws = [
        # Magic constants:
        # <https://www.php.net/manual/en/language.constants.predefined.php>
        "__CLASS__",
        "__DIR__",
        "__FILE__",
        "__FUNCTION__",
        "__COMPILER_HALT_OFFSET__",
        "__LINE__",
        "__METHOD__",
        "__NAMESPACE__",
        "__TRAIT__",
        # Function that look like language construct or language construct that look like function:
        # List of keywords that may not require parenthesis
        "die",
        "echo",
        "exit",
        "include",
        "include_once",
        "print",
        "require",
        "require_once",
        # These are not language construct (function) but operate on the currently-executing function and can access the current symbol table
        # Other keywords:
        # <https://www.php.net/manual/en/reserved.php>
        # <https://www.php.net/manual/en/language.types.type-juggling.php>
        "array",
        "abstract",
        "and",
        "as",
        "binary",
        "bool",
        "boolean",
        "break",
        "callable",
        "case",
        "catch",
        "class",
        "clone",
        "const",
        "continue",
        "declare",
        "default",
        "do",
        "double",
        "else",
        "elseif",
        "empty",
        "enddeclare",
        "endfor",
        "endforeach",
        "endif",
        "endswitch",
        "endwhile",
        "enum",
        "eval",
        "extends",
        "final",
        "finally",
        "float",
        "for",
        "foreach",
        "from",
        "global",
        "goto",
        "if",
        "implements",
        "instanceof",
        "insteadof",
        "int",
        "integer",
        "interface",
        "isset",
        "iterable",
        "list",
        "match|0",
        "mixed",
        "new",
        "never",
        "object",
        "or",
        "private",
        "protected",
        "public",
        "readonly",
        "real",
        "return",
        "string",
        "switch",
        "throw",
        "trait",
        "try",
        "unset",
        "use",
        "var",
        "void",
        "while",
        "xor",
        "yield",
      ]

      built_ins = [
        # Standard PHP library:
        # <https://www.php.net/manual/en/book.spl.php>
        "Error|0",
        "AppendIterator",
        "ArgumentCountError",
        "ArithmeticError",
        "ArrayIterator",
        "ArrayObject",
        "AssertionError",
        "BadFunctionCallException",
        "BadMethodCallException",
        "CachingIterator",
        "CallbackFilterIterator",
        "CompileError",
        "Countable",
        "DirectoryIterator",
        "DivisionByZeroError",
        "DomainException",
        "EmptyIterator",
        "ErrorException",
        "Exception",
        "FilesystemIterator",
        "FilterIterator",
        "GlobIterator",
        "InfiniteIterator",
        "InvalidArgumentException",
        "IteratorIterator",
        "LengthException",
        "LimitIterator",
        "LogicException",
        "MultipleIterator",
        "NoRewindIterator",
        "OutOfBoundsException",
        "OutOfRangeException",
        "OuterIterator",
        "OverflowException",
        "ParentIterator",
        "ParseError",
        "RangeException",
        "RecursiveArrayIterator",
        "RecursiveCachingIterator",
        "RecursiveCallbackFilterIterator",
        "RecursiveDirectoryIterator",
        "RecursiveFilterIterator",
        "RecursiveIterator",
        "RecursiveIteratorIterator",
        "RecursiveRegexIterator",
        "RecursiveTreeIterator",
        "RegexIterator",
        "RuntimeException",
        "SeekableIterator",
        "SplDoublyLinkedList",
        "SplFileInfo",
        "SplFileObject",
        "SplFixedArray",
        "SplHeap",
        "SplMaxHeap",
        "SplMinHeap",
        "SplObjectStorage",
        "SplObserver",
        "SplPriorityQueue",
        "SplQueue",
        "SplStack",
        "SplSubject",
        "SplTempFileObject",
        "TypeError",
        "UnderflowException",
        "UnexpectedValueException",
        "UnhandledMatchError",
        # Reserved interfaces:
        # <https://www.php.net/manual/en/reserved.interfaces.php>
        "ArrayAccess",
        "BackedEnum",
        "Closure",
        "Fiber",
        "Generator",
        "Iterator",
        "IteratorAggregate",
        "Serializable",
        "Stringable",
        "Throwable",
        "Traversable",
        "UnitEnum",
        "WeakReference",
        "WeakMap",
        # Reserved classes:
        # <https://www.php.net/manual/en/reserved.classes.php>
        "Directory",
        "__PHP_Incomplete_Class",
        "parent",
        "php_user_filter",
        "self",
        "static",
        "stdClass",
      ]

      # Dual-case keywords
      # ["then","FILE"] => ["then", "THEN", "FILE", "file"]
      dual_case = [] of String
      literals.each do |item|
        dual_case << item
        if item.downcase == item
          dual_case << item.upcase
        else
          dual_case << item.downcase
        end
      end

      keywords = {} of String => KeywordsVal
      keywords["keyword"] = kws
      keywords["literal"] = dual_case
      keywords["built_in"] = built_ins

      normalize_keywords = ->(items : Array(String)) {
        items.map { |item| item.gsub(/\|\d+$/, "") }
      }

      constructor_call = Mode.new.apply(variants: [
        Mode.new.apply(
          match: [
            /new/,
            regex.concat(whitespace, "+"),
            # to prevent built ins from being confused as the class constructor call
            regex.concat("(?!", normalize_keywords.call(built_ins).join("\\b|"), "\\b)"),
            pascal_case_class_name_re,
          ] of String | Regex,
          scope: {
            "1" => "keyword",
            "4" => "title.class",
          },
        ),
      ] of Mode)

      constant_reference = regex.concat(ident_re, "\\b(?!\\()")

      left_and_right_side_of_double_colon = Mode.new.apply(variants: [
        Mode.new.apply(
          match: [
            regex.concat(
              /::/,
              regex.lookahead(/(?!class\b)/)
            ),
            constant_reference,
          ] of String | Regex,
          scope: {"2" => "variable.constant"},
        ),
        Mode.new.apply(
          match: [
            /::/,
            /class/,
          ] of String | Regex,
          scope: {"2" => "variable.language"},
        ),
        Mode.new.apply(
          match: [
            pascal_case_class_name_re,
            regex.concat(
              /::/,
              regex.lookahead(/(?!class\b)/)
            ),
            constant_reference,
          ] of String | Regex,
          scope: {
            "1" => "title.class",
            "3" => "variable.constant",
          },
        ),
        Mode.new.apply(
          match: [
            pascal_case_class_name_re,
            regex.concat(
              "::",
              regex.lookahead(/(?!class\b)/)
            ),
          ] of String | Regex,
          scope: {"1" => "title.class"},
        ),
        Mode.new.apply(
          match: [
            pascal_case_class_name_re,
            /::/,
            /class/,
          ] of String | Regex,
          scope: {
            "1" => "title.class",
            "3" => "variable.language",
          },
        ),
      ] of Mode)

      named_argument = Mode.new.apply(
        scope: "attr",
        match: regex.concat(ident_re, regex.lookahead(":"), regex.lookahead(/(?!::)/)),
      )
      params_mode = Mode.new.apply(
        relevance: 0,
        begin: /\(/,
        end: /\)/,
        keywords: keywords,
        contains: [
          named_argument,
          variable,
          left_and_right_side_of_double_colon,
          MODES::C_BLOCK_COMMENT_MODE,
          MODES::C_LINE_COMMENT_MODE,
          MODES::HASH_COMMENT_MODE,
          string_mode,
          number,
          constructor_call,
        ] of Mode,
      )
      function_invoke = Mode.new.apply(
        relevance: 0,
        match: [
          /\b/,
          # to prevent keywords from being confused as the function title
          regex.concat("(?!fn\\b|function\\b|", normalize_keywords.call(kws).join("\\b|"), "|", normalize_keywords.call(built_ins).join("\\b|"), "\\b)"),
          ident_re,
          regex.concat(whitespace, "*"),
          regex.lookahead(/(?=\()/),
        ] of String | Regex,
        scope: {"3" => "title.function.invoke"},
        contains: [params_mode] of Mode
      )
      params_mode.contains.not_nil! << function_invoke

      attribute_contains = [
        named_argument,
        left_and_right_side_of_double_colon,
        MODES::C_BLOCK_COMMENT_MODE,
        MODES::C_LINE_COMMENT_MODE,
        MODES::HASH_COMMENT_MODE,
        string_mode,
        number,
        constructor_call,
      ] of Mode

      attribute_keywords = ->{
        kw = {} of String => KeywordsVal
        kw["literal"] = literals
        kw["keyword"] = ["new", "array"]
        kw
      }

      attributes = Mode.new.apply(
        begin: regex.concat(/#\[\s*\\?/,
          regex.either([
            pascal_case_class_name_re,
            upcase_name_re,
          ] of String | Regex)
        ),
        begin_scope: "meta",
        end: /]/,
        end_scope: "meta",
        keywords: attribute_keywords.call,
        contains: (
          [
            Mode.new.apply(
              begin: /\[/,
              end: /]/,
              keywords: attribute_keywords.call,
              contains: ([Mode.self_marker] of Mode).concat(attribute_contains)
            ),
          ] of Mode
        ).concat(attribute_contains).concat([
          Mode.new.apply(
            scope: "meta",
            variants: [
              Mode.new.apply(match: pascal_case_class_name_re),
              Mode.new.apply(match: upcase_name_re),
            ] of Mode
          ),
        ] of Mode)
      )

      Mode.new.apply(
        case_insensitive: false,
        keywords: keywords,
        contains: [
          attributes,
          MODES::HASH_COMMENT_MODE,
          hljs.comment("//", "$"),
          hljs.comment(
            "/\\*",
            "\\*/",
            Mode.new.apply(contains: [
              Mode.new.apply(
                scope: "doctag",
                match: "@[A-Za-z]+"
              ),
            ] of Mode)
          ),
          Mode.new.apply(
            match: /__halt_compiler\(\);/,
            keywords: "__halt_compiler",
            starts: Mode.new.apply(
              scope: "comment",
              end: MATCH_NOTHING_RE,
              contains: [
                Mode.new.apply(
                  match: /\?>/,
                  scope: "meta",
                  ends_parent: true
                ),
              ] of Mode
            )
          ),
          preprocessor,
          Mode.new.apply(
            scope: "variable.language",
            match: /\$this\b/
          ),
          variable,
          function_invoke,
          left_and_right_side_of_double_colon,
          Mode.new.apply(
            match: [
              /const/,
              /\s/,
              ident_re,
            ] of String | Regex,
            scope: {
              "1" => "keyword",
              "3" => "variable.constant",
            },
          ),
          constructor_call,
          Mode.new.apply(
            scope: "function",
            relevance: 0,
            begin_keywords: "fn function",
            end: /[;{]/,
            exclude_end: true,
            illegal: "[$%\\[]",
            contains: [
              Mode.new.apply(begin_keywords: "use"),
              MODES::UNDERSCORE_TITLE_MODE,
              Mode.new.apply(
                begin: "=>", # No markup, just a relevance booster
                ends_parent: true
              ),
              Mode.new.apply(
                scope: "params",
                begin: "\\(",
                end: "\\)",
                exclude_begin: true,
                exclude_end: true,
                keywords: keywords,
                contains: [
                  Mode.self_marker,
                  attributes,
                  variable,
                  left_and_right_side_of_double_colon,
                  MODES::C_BLOCK_COMMENT_MODE,
                  MODES::C_LINE_COMMENT_MODE,
                  MODES::HASH_COMMENT_MODE,
                  string_mode,
                  number,
                ] of Mode
              ),
            ] of Mode
          ),
          Mode.new.apply(
            scope: "class",
            variants: [
              Mode.new.apply(
                begin_keywords: "enum",
                illegal: /[($"]/
              ),
              Mode.new.apply(
                begin_keywords: "class interface trait",
                illegal: /[:($"]/
              ),
            ] of Mode,
            relevance: 0,
            end: /\{/,
            exclude_end: true,
            contains: [
              Mode.new.apply(begin_keywords: "extends implements"),
              MODES::UNDERSCORE_TITLE_MODE,
            ] of Mode
          ),
          # both use and namespace still use "old style" rules (vs multi-match)
          # because the namespace name can include `\` and we still want each
          # element to be treated as its own *individual* title
          Mode.new.apply(
            begin_keywords: "namespace",
            relevance: 0,
            end: ";",
            illegal: /[.']/,
            contains: [MODES::UNDERSCORE_TITLE_MODE.inherit(Mode.new.apply(scope: "title.class"))] of Mode
          ),
          Mode.new.apply(
            begin_keywords: "use",
            relevance: 0,
            end: ";",
            contains: [
              # TODO: title.function vs title.class
              Mode.new.apply(
                match: /\b(as|const|function)\b/,
                scope: "keyword"
              ),
              # TODO: could be title.class or title.function
              MODES::UNDERSCORE_TITLE_MODE,
            ] of Mode
          ),
          string_mode,
          number,
        ] of Mode
      )
    end
  end

  Languages.register("php", ->(hljs : HLJS) { Php.defined(hljs) })
end
