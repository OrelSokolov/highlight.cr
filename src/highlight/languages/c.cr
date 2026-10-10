# Порт lib/languages/c.js (highlight.js 11.12.0).

module Highlight::Languages
  module CLang
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
      function_type_re = "(" +
        decltype_auto_re + "|" +
        regex.optional(namespace_re) +
        "[a-zA-Z_]\\w*" + regex.optional(template_argument_re) +
        ")"

      # C11 <stdatomic.h> atomic type names. This is an explicit whitelist so that
      # C11 atomic *functions* (atomic_init, atomic_store, atomic_load,
      # atomic_fetch_add, ...) are not mistakenly highlighted as types. See #3837.
      atomic_types = regex.concat(/\batomic_/, regex.either([
        "bool",
        "char",
        "schar",
        "uchar",
        "short",
        "ushort",
        "int",
        "uint",
        "long",
        "ulong",
        "llong",
        "ullong",
        "char16_t",
        "char32_t",
        "wchar_t",
        "int_least8_t",
        "uint_least8_t",
        "int_least16_t",
        "uint_least16_t",
        "int_least32_t",
        "uint_least32_t",
        "int_least64_t",
        "uint_least64_t",
        "int_fast8_t",
        "uint_fast8_t",
        "int_fast16_t",
        "uint_fast16_t",
        "int_fast32_t",
        "uint_fast32_t",
        "int_fast64_t",
        "uint_fast64_t",
        "intptr_t",
        "uintptr_t",
        "size_t",
        "ptrdiff_t",
        "intmax_t",
        "uintmax_t",
      ] of String | Regex), /\b/)
      types = Mode.new.apply(
        class_name: "type",
        variants: [
          Mode.new.apply(begin: "\\b[a-z\\d_]*_t\\b"),
          Mode.new.apply(match: atomic_types),
        ] of Mode
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
          Mode.new.apply(match: /\b(0b[01']+)/),
          Mode.new.apply(match: /(-?)\b([\d']+(\.[\d']*)?|\.[\d']+)((ll|LL|l|L)(u|U)?|(u|U)(ll|LL|l|L)?|f|F|b|B)/),
          Mode.new.apply(match: /(-?)\b(0[xX][a-fA-F0-9]+(?:'[a-fA-F0-9]+)*(?:\.[a-fA-F0-9]*(?:'[a-fA-F0-9]*)*)?(?:[pP][-+]?[0-9]+)?(l|L)?(u|U)?)/),
          Mode.new.apply(match: /(-?)\b\d+(?:'\d+)*(?:\.\d*(?:'\d*)*)?(?:[eE][-+]?\d+)?/),
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
                                "pragma _Pragma ifdef ifndef elifdef elifndef include"} of String => KeywordsVal,
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

      c_keywords = [
        "asm",
        "auto",
        "break",
        "case",
        "continue",
        "default",
        "do",
        "else",
        "enum",
        "extern",
        "for",
        "fortran",
        "goto",
        "if",
        "inline",
        "register",
        "restrict",
        "return",
        "sizeof",
        "typeof",
        "typeof_unqual",
        "struct",
        "switch",
        "typedef",
        "union",
        "volatile",
        "while",
        "_Alignas",
        "_Alignof",
        "_Atomic",
        "_Generic",
        "_Noreturn",
        "_Static_assert",
        "_Thread_local",
        # aliases
        "alignas",
        "alignof",
        "noreturn",
        "static_assert",
        "thread_local",
        # not a C keyword but is, for all intents and purposes, treated exactly like one.
        "_Pragma",
      ]

      c_types = [
        "float",
        "double",
        "signed",
        "unsigned",
        "int",
        "short",
        "long",
        "char",
        "void",
        "_Bool",
        "_BitInt",
        "_Complex",
        "_Imaginary",
        "_Decimal32",
        "_Decimal64",
        "_Decimal96",
        "_Decimal128",
        "_Decimal64x",
        "_Decimal128x",
        "_Float16",
        "_Float32",
        "_Float64",
        "_Float128",
        "_Float32x",
        "_Float64x",
        "_Float128x",
        # modifiers
        "const",
        "static",
        "constexpr",
        # aliases
        "complex",
        "bool",
        "imaginary",
      ]

      keywords = {} of String => KeywordsVal
      keywords["keyword"] = c_keywords
      keywords["type"] = c_types
      keywords["literal"] = "true false NULL"
      # TODO: apply hinting work similar to what was done in cpp.js
      keywords["built_in"] = "std string wstring cin cout cerr clog stdin stdout stderr stringstream istringstream ostringstream " +
                             "auto_ptr deque list queue stack vector map set pair bitset multiset multimap unordered_set " +
                             "unordered_map unordered_multiset unordered_multimap priority_queue make_pair array shared_ptr abort terminate abs acos " +
                             "asin atan2 atan calloc ceil cosh cos exit exp fabs floor fmod fprintf fputs free frexp " +
                             "fscanf future isalnum isalpha iscntrl isdigit isgraph islower isprint ispunct isspace isupper " +
                             "isxdigit tolower toupper labs ldexp log10 log malloc realloc memchr memcmp memcpy memset modf pow " +
                             "printf putchar puts scanf sinh sin snprintf sprintf sqrt sscanf strcat strchr strcmp " +
                             "strcpy strcspn strlen strncat strncmp strncpy strpbrk strrchr strspn strstr tanh tan " +
                             "vfprintf vprintf vsprintf endl initializer_list unique_ptr"

      expression_contains = preprocessors + ([
        types,
        c_line_comment_mode,
        MODES::C_BLOCK_COMMENT_MODE,
        numbers,
        strings,
      ] of Mode)

      expression_context = Mode.new.apply(
        # This mode covers expression context where we can't expect a function
        # definition and shouldn't highlight anything that looks like one:
        # `return some()`, `else if()`, `(x*sum(1, 2))`
        variants: [
          Mode.new.apply(begin: /=/, end: /;/),
          Mode.new.apply(begin: /\(/, end: /\)/),
          Mode.new.apply(begin_keywords: "new throw return else", end: /;/),
        ] of Mode,
        keywords: keywords,
        contains: expression_contains + ([
          Mode.new.apply(
            begin: /\(/,
            end: /\)/,
            keywords: keywords,
            contains: expression_contains + ([Mode.self_marker] of Mode),
            relevance: 0
          ),
        ] of Mode),
        relevance: 0
      )

      function_declaration = Mode.new.apply(
        begin: "(" + function_type_re + "[\\*&\\s]+){1," + max_function_type_tokens.to_s + "}" + function_title,
        return_begin: true,
        end: /[{;=]/,
        exclude_end: true,
        keywords: keywords,
        illegal: /[^\w\s\*&:<>.]/,
        contains: ([
          # to prevent it from being confused as the function title
          Mode.new.apply(
            begin: decltype_auto_re,
            keywords: keywords,
            relevance: 0
          ),
          Mode.new.apply(
            begin: function_title,
            return_begin: true,
            contains: [title_mode.inherit(Mode.new.apply(class_name: "title.function"))] of Mode,
            relevance: 0
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
            keywords: keywords,
            relevance: 0,
            contains: [
              c_line_comment_mode,
              MODES::C_BLOCK_COMMENT_MODE,
              strings,
              numbers,
              types,
              # Count matching parentheses.
              Mode.new.apply(
                begin: /\(/,
                end: /\)/,
                keywords: keywords,
                relevance: 0,
                contains: [
                  Mode.self_marker,
                  c_line_comment_mode,
                  MODES::C_BLOCK_COMMENT_MODE,
                  strings,
                  numbers,
                  types,
                ] of Mode
              ),
            ] of Mode
          ),
          types,
          c_line_comment_mode,
          MODES::C_BLOCK_COMMENT_MODE,
        ] of Mode).concat(preprocessors)
      )

      mode = Mode.new.apply(
        name: "C",
        aliases: ["h"],
        keywords: keywords,
        # Until differentiations are added between `c` and `cpp`, `c` will
        # not be auto-detected to avoid auto-detect conflicts between C and C++
        disable_autodetect: true,
        illegal: "</",
        contains: ([expression_context] of Mode)
          .concat([function_declaration] of Mode)
          .concat(expression_contains)
          .concat(preprocessors)
          .concat([
            Mode.new.apply(
              begin: IDENT_RE + "::",
              keywords: keywords
            ),
            Mode.new.apply(
              class_name: "class",
              begin_keywords: "enum class struct union",
              end: /[{;:<>=]/,
              contains: [
                Mode.new.apply(begin_keywords: "final class struct"),
                MODES::TITLE_MODE,
              ] of Mode
            ),
          ] of Mode)
      )
      mode.exports = {
        "preprocessor" => preprocessor,
        "strings"      => strings,
        "keywords"     => keywords,
      } of String => Mode | KeywordsVal | Array(Mode)
      mode
    end
  end

  Languages.register("c", ->(hljs : HLJS) { CLang.defined(hljs) })
end
