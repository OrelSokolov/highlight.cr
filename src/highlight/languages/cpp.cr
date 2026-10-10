# Порт lib/languages/cpp.js (highlight.js 11.12.0).

module Highlight::Languages
  module Cpp
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # added for historic reasons because `hljs.C_LINE_COMMENT_MODE` does
      # not include such support nor can we be sure all the grammars depending
      # on it would desire this behavior
      c_line_comment_mode = hljs.comment("//", "$", Mode.new.apply(contains: [
        Mode.new.apply(begin: /\\\n/),
      ] of Mode))
      decltype_auto_re = "decltype\\(auto\\)"
      namespace_re = "[a-zA-Z_]\\w*::"
      template_argument_re = "<[^<>]+>"
      function_type_re = "(?!struct)(" +
        decltype_auto_re + "|" +
        regex.optional(namespace_re) +
        "[a-zA-Z_]\\w*" + regex.optional(template_argument_re) +
        ")"

      cpp_primitive_types = Mode.new.apply(
        class_name: "type",
        begin: "\\b[a-z\\d_]*_t\\b"
      )

      # https://en.cppreference.com/w/cpp/language/escape
      # \\ \x \xFF \u2837 \u00323747 \374
      character_escapes = "\\\\(x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4,8}|[0-7]{3}|\\S)"
      strings = Mode.new.apply(
        class_name: "string",
        variants: [
          Mode.new.apply(
            begin: "(u8?|U|L)?\"",
            end: "\"",
            illegal: "\\n",
            contains: [MODES::BACKSLASH_ESCAPE] of Mode
          ),
          Mode.new.apply(
            begin: "(u8?|U|L)?'(" + character_escapes + "|.)",
            end: "'",
            illegal: "."
          ),
          # https://en.cppreference.com/w/cpp/language/string_literal
          # a d-char-sequence never contains parentheses, backslashes or whitespace;
          # quotes are excluded as well so the closing delimiter cannot swallow the
          # quote that actually terminates the literal
          hljs.end_same_as_begin(Mode.new.apply(
            begin: /(?:u8?|U|L)?R"([^()\\\s"]{0,16})\(/,
            end: /\)([^()\\\s"]{0,16})"/
          )),
        ] of Mode
      )

      numbers = Mode.new.apply(
        class_name: "number",
        variants: [
          # Floating-point literal.
          Mode.new.apply(begin:
            "[+-]?(?:" + # Leading sign.
              # Decimal.
              "(?:" +
              "\\b[0-9](?:'?[0-9])*\\.(?:[0-9](?:'?[0-9])*)?" +
              "|\\.[0-9](?:'?[0-9])*" +
              ")(?:[Ee][+-]?[0-9](?:'?[0-9])*)?" +
              "|\\b[0-9](?:'?[0-9])*[Ee][+-]?[0-9](?:'?[0-9])*" +
              # Hexadecimal.
              "|\\b0[Xx](?:" +
              "[0-9A-Fa-f](?:'?[0-9A-Fa-f])*(?:\\.(?:[0-9A-Fa-f](?:'?[0-9A-Fa-f])*)?)?" +
              "|\\.[0-9A-Fa-f](?:'?[0-9A-Fa-f])*" +
              ")[Pp][+-]?[0-9](?:'?[0-9])*" +
              ")(?:" + # Literal suffixes.
              "[Ff](?:16|32|64|128)?" +
              "|(BF|bf)16" +
              "|[Ll]" +
              "|" + # Literal suffix is optional.
              ")"
          ),
          # Integer literal.
          Mode.new.apply(begin:
            "[+-]?\\b(?:" + # Leading sign.
              "0[Bb][01](?:'?[01])*" + # Binary.
              "|0[Xx][0-9A-Fa-f](?:'?[0-9A-Fa-f])*" + # Hexadecimal.
              "|0(?:'?[0-7])*" + # Octal or just a lone zero.
              "|[1-9](?:'?[0-9])*" + # Decimal.
              ")(?:" + # Literal suffixes.
              "[Uu](?:LL?|ll?)" +
              "|[Uu][Zz]?" +
              "|(?:LL?|ll?)[Uu]?" +
              "|[Zz][Uu]" +
              "|" + # Literal suffix is optional.
              ")"
            # Note: there are user-defined literal suffixes too, but perhaps having the custom suffix not part of the
            # literal highlight actually makes it stand out more.
          ),
        ] of Mode,
        relevance: 0
      )

      # `#include` is the only preprocessor directive that takes an angle-bracket
      # quoted header (`#include <header>`). Scoping that rule to `#include` keeps
      # the greedy `<...>` match from eating a `>` that belongs to the body of
      # another directive (e.g. `#define what do { cout << ">"; } while (0)`),
      # which would otherwise leave an unbalanced `"` and break highlighting for
      # the rest of the file. See issue #3505.
      preprocessor_include = Mode.new.apply(
        scope: "meta",
        begin: /#\s*include\b/,
        end: /$/,
        keywords: {"keyword" => "include"} of String => KeywordsVal,
        contains: [
          # the `\` at the end of a line signaling continuation
          Mode.new.apply(begin: /\\\n/),
          strings,
          Mode.new.apply(
            scope: "string",
            begin: /<.*?>/
          ),
          c_line_comment_mode,
          MODES::C_BLOCK_COMMENT_MODE,
        ] of Mode
      )

      preprocessor = Mode.new.apply(
        class_name: "meta",
        begin: /#\s*[a-z]+\b/,
        end: /$/,
        keywords: {"keyword" => "if else elif endif define undef warning error line " +
                                "pragma _Pragma ifdef ifndef include"} of String => KeywordsVal,
        contains: [
          Mode.new.apply(
            begin: /\\\n/,
            relevance: 0
          ),
          strings.inherit(Mode.new.apply(class_name: "string")),
          c_line_comment_mode,
          MODES::C_BLOCK_COMMENT_MODE,
        ] of Mode
      )

      preprocessors = [
        preprocessor_include,
        preprocessor,
      ] of Mode

      title_mode = Mode.new.apply(
        class_name: "title",
        begin: regex.optional(namespace_re) + IDENT_RE,
        relevance: 0
      )

      function_title = regex.optional(namespace_re) + IDENT_RE + "\\s*\\("
      # Bounded on purpose: an unbounded quantifier here consumes an arbitrarily
      # long run of words, and when no function title follows it the engine retries
      # the title at every token boundary of that run - quadratic in the size of
      # the document.  See #4362.
      max_function_type_tokens = 12

      # https://en.cppreference.com/w/cpp/keyword
      reserved_keywords = [
        "alignas",
        "alignof",
        "and",
        "and_eq",
        "asm",
        "atomic_cancel",
        "atomic_commit",
        "atomic_noexcept",
        "auto",
        "bitand",
        "bitor",
        "break",
        "case",
        "catch",
        "class",
        "co_await",
        "co_return",
        "co_yield",
        "compl",
        "concept",
        "const_cast|10",
        "consteval",
        "constexpr",
        "constinit",
        "continue",
        "decltype",
        "default",
        "delete",
        "do",
        "dynamic_cast|10",
        "else",
        "enum",
        "explicit",
        "export",
        "extern",
        "false",
        "final",
        "for",
        "friend",
        "goto",
        "if",
        "import",
        "inline",
        "module",
        "mutable",
        "namespace",
        "new",
        "noexcept",
        "not",
        "not_eq",
        "nullptr",
        "operator",
        "or",
        "or_eq",
        "override",
        "private",
        "protected",
        "public",
        "reflexpr",
        "register",
        "reinterpret_cast|10",
        "requires",
        "return",
        "sizeof",
        "static_assert",
        "static_cast|10",
        "struct",
        "switch",
        "synchronized",
        "template",
        "this",
        "thread_local",
        "throw",
        "transaction_safe",
        "transaction_safe_dynamic",
        "true",
        "try",
        "typedef",
        "typeid",
        "typename",
        "union",
        "using",
        "virtual",
        "volatile",
        "while",
        "xor",
        "xor_eq",
      ]

      # https://en.cppreference.com/w/cpp/keyword
      reserved_types = [
        "bool",
        "char",
        "char16_t",
        "char32_t",
        "char8_t",
        "double",
        "float",
        "int",
        "long",
        "short",
        "void",
        "wchar_t",
        "unsigned",
        "signed",
        "const",
        "static",
      ]

      type_hints = [
        "any",
        "auto_ptr",
        "barrier",
        "binary_semaphore",
        "bitset",
        "complex",
        "condition_variable",
        "condition_variable_any",
        "counting_semaphore",
        "deque",
        "false_type",
        "flat_map",
        "flat_set",
        "future",
        "imaginary",
        "initializer_list",
        "istringstream",
        "jthread",
        "latch",
        "lock_guard",
        "multimap",
        "multiset",
        "mutex",
        "optional",
        "ostringstream",
        "packaged_task",
        "pair",
        "promise",
        "priority_queue",
        "queue",
        "recursive_mutex",
        "recursive_timed_mutex",
        "scoped_lock",
        "set",
        "shared_future",
        "shared_lock",
        "shared_mutex",
        "shared_timed_mutex",
        "shared_ptr",
        "stack",
        "string_view",
        "stringstream",
        "timed_mutex",
        "thread",
        "true_type",
        "tuple",
        "unique_lock",
        "unique_ptr",
        "unordered_map",
        "unordered_multimap",
        "unordered_multiset",
        "unordered_set",
        "variant",
        "vector",
        "weak_ptr",
        "wstring",
        "wstring_view",
      ]

      function_hints = [
        "abort",
        "abs",
        "acos",
        "apply",
        "as_const",
        "asin",
        "atan",
        "atan2",
        "calloc",
        "ceil",
        "cerr",
        "cin",
        "clog",
        "cos",
        "cosh",
        "cout",
        "declval",
        "endl",
        "exchange",
        "exit",
        "exp",
        "fabs",
        "floor",
        "fmod",
        "forward",
        "fprintf",
        "fputs",
        "free",
        "frexp",
        "fscanf",
        "future",
        "invoke",
        "isalnum",
        "isalpha",
        "iscntrl",
        "isdigit",
        "isgraph",
        "islower",
        "isprint",
        "ispunct",
        "isspace",
        "isupper",
        "isxdigit",
        "labs",
        "launder",
        "ldexp",
        "log",
        "log10",
        "make_pair",
        "make_shared",
        "make_shared_for_overwrite",
        "make_tuple",
        "make_unique",
        "malloc",
        "memchr",
        "memcmp",
        "memcpy",
        "memset",
        "modf",
        "move",
        "pow",
        "printf",
        "putchar",
        "puts",
        "realloc",
        "scanf",
        "sin",
        "sinh",
        "snprintf",
        "sprintf",
        "sqrt",
        "sscanf",
        "std",
        "stderr",
        "stdin",
        "stdout",
        "strcat",
        "strchr",
        "strcmp",
        "strcpy",
        "strcspn",
        "strlen",
        "strncat",
        "strncmp",
        "strncpy",
        "strpbrk",
        "strrchr",
        "strspn",
        "strstr",
        "swap",
        "tan",
        "tanh",
        "terminate",
        "to_underlying",
        "tolower",
        "toupper",
        "vfprintf",
        "visit",
        "vprintf",
        "vsprintf",
      ]

      literals = [
        "NULL",
        "false",
        "nullopt",
        "nullptr",
        "true",
      ]

      # https://en.cppreference.com/w/cpp/keyword
      built_in = ["_Pragma"]

      cpp_keywords = {} of String => KeywordsVal
      cpp_keywords["type"] = reserved_types
      cpp_keywords["keyword"] = reserved_keywords
      cpp_keywords["literal"] = literals
      cpp_keywords["built_in"] = built_in
      cpp_keywords["_type_hints"] = type_hints

      function_dispatch = Mode.new.apply(
        class_name: "function.dispatch",
        relevance: 0,
        keywords: {
          # Only for relevance, not highlighting.
          "_hint" => function_hints,
        } of String => KeywordsVal,
        begin: regex.concat(
          /\b/,
          "(?!#{reserved_keywords.join("|")})",
          IDENT_RE,
          regex.lookahead(/(<[^<>]+>|)\s*\(/))
      )

      expression_contains = ([function_dispatch] of Mode)
        .concat(preprocessors)
        .concat([cpp_primitive_types, c_line_comment_mode, MODES::C_BLOCK_COMMENT_MODE, numbers, strings] of Mode)

      expression_context = Mode.new.apply(
        # This mode covers expression context where we can't expect a function
        # definition and shouldn't highlight anything that looks like one:
        # `return some()`, `else if()`, `(x*sum(1, 2))`
        variants: [
          Mode.new.apply(begin: /=/, end: /;/),
          Mode.new.apply(begin: /\(/, end: /\)/),
          Mode.new.apply(begin_keywords: "new throw return else", end: /;/),
        ] of Mode,
        keywords: cpp_keywords,
        contains: expression_contains + ([
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            keywords: cpp_keywords,
            contains: expression_contains + ([Mode.self_marker] of Mode),
            relevance: 0
          ),
        ] of Mode),
        relevance: 0
      )

      function_declaration = Mode.new.apply(
        class_name: "function",
        begin: "(" + function_type_re + "[\\*&\\s]+){1," + max_function_type_tokens.to_s + "}" + function_title,
        return_begin: true,
        end: /[{;=]/,
        exclude_end: true,
        keywords: cpp_keywords,
        illegal: /[^\w\s\*&:<>.]/,
        contains: ([# to prevent it from being confused as the function title
          Mode.new.apply(
            begin: decltype_auto_re,
            keywords: cpp_keywords,
            relevance: 0
          ),
          Mode.new.apply(
            begin: function_title,
            return_begin: true,
            contains: [title_mode] of Mode,
            relevance: 0
          ),
          # needed because we do not have look-behind on the below rule
          # to prevent it from grabbing the final : in a :: pair
          Mode.new.apply(
            begin: /::/,
            relevance: 0
          ),
          # initializers
          Mode.new.apply(
            begin: /:/,
            ends_with_parent: true,
            contains: [
              strings,
              numbers,
            ] of Mode
          ),
          # allow for multiple declarations, e.g.:
          # extern void f(int), g(char);
          Mode.new.apply(
            relevance: 0,
            match: /,/
          ),
          Mode.new.apply(
            class_name: "params",
            begin: /\(/,
            end: /\)/,
            keywords: cpp_keywords,
            relevance: 0,
            contains: [
              c_line_comment_mode,
              MODES::C_BLOCK_COMMENT_MODE,
              strings,
              numbers,
              cpp_primitive_types,
              # Count matching parentheses.
              Mode.new.apply(
                begin: /\(/,
                end: /\)/,
                keywords: cpp_keywords,
                relevance: 0,
                contains: [
                  Mode.self_marker,
                  c_line_comment_mode,
                  MODES::C_BLOCK_COMMENT_MODE,
                  strings,
                  numbers,
                  cpp_primitive_types,
                ] of Mode
              ),
            ] of Mode
          ),
          cpp_primitive_types,
          c_line_comment_mode,
          MODES::C_BLOCK_COMMENT_MODE,
        ] of Mode).concat(preprocessors)
      )

      Mode.new.apply(
        name: "C++",
        aliases: [
          "cc",
          "c++",
          "h++",
          "hpp",
          "hh",
          "hxx",
          "cxx",
        ],
        keywords: cpp_keywords,
        illegal: "</",
        class_name_aliases: {"function.dispatch" => "built_in"},
        contains: ([] of Mode)
          .concat([expression_context, function_declaration, function_dispatch] of Mode)
          .concat(expression_contains)
          .concat(preprocessors)
          .concat([
            # containers: ie, `vector <int> rooms (9);`
            Mode.new.apply(
              begin: "\\b(deque|list|queue|priority_queue|pair|stack|vector|map|set|bitset|multiset|multimap|unordered_map|unordered_set|unordered_multiset|unordered_multimap|array|tuple|optional|variant|function|flat_map|flat_set)\\s*<(?!<)",
              end: ">",
              keywords: cpp_keywords,
              contains: [
                Mode.self_marker,
                cpp_primitive_types,
              ] of Mode
            ),
            Mode.new.apply(
              begin: IDENT_RE + "::",
              keywords: cpp_keywords
            ),
            Mode.new.apply(
              match: [
                # extra complexity to deal with `enum class` and `enum struct`
                /\b(?:enum(?:\s+(?:class|struct))?|class|struct|union)/,
                /\s+/,
                /\w+/,
              ] of String | Regex,
              scope: {
                "1" => "keyword",
                "3" => "title.class",
              }
            ),
          ] of Mode)
      )
    end
  end

  Languages.register("cpp", ->(hljs : HLJS) { Cpp.defined(hljs) })
end
