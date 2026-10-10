# Порт lib/languages/vbnet.js (highlight.js 11.12.0).

module Highlight::Languages
  module Vbnet
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # Character Literal
      # Either a single character ("a"C) or an escaped double quote (""""C).
      character = Mode.new.apply(
        class_name: "string",
        begin: %r("(""|[^/n])"C\b)
      )

      string_mode = Mode.new.apply(
        class_name: "string",
        begin: /"/,
        end: /"/,
        illegal: /\n/,
        contains: [
          # double quote escape
          Mode.new.apply(begin: /""/),
        ] of Mode
      )

      # Date Literals consist of a date, a time, or both separated by whitespace, surrounded by #
      mm_dd_yyyy = /\d{1,2}\/\d{1,2}\/\d{4}/
      yyyy_mm_dd = /\d{4}-\d{1,2}-\d{1,2}/
      time_12h = /(\d|1[012])(:\d+){0,2} *(AM|PM)/
      time_24h = /\d{1,2}(:\d{1,2}){1,2}/
      date_mode = Mode.new.apply(
        class_name: "literal",
        variants: [
          # #YYYY-MM-DD# (ISO-Date) or #M/D/YYYY# (US-Date)
          Mode.new.apply(begin: regex.concat(/# */, regex.either([yyyy_mm_dd, mm_dd_yyyy]), / *#/)),
          # #H:mm[:ss]# (24h Time)
          Mode.new.apply(begin: regex.concat(/# */, time_24h, / *#/)),
          # #h[:mm[:ss]] A# (12h Time)
          Mode.new.apply(begin: regex.concat(/# */, time_12h, / *#/)),
          # date plus time
          Mode.new.apply(begin: regex.concat(
            /# */,
            regex.either([yyyy_mm_dd, mm_dd_yyyy]),
            / +/,
            regex.either([time_12h, time_24h]),
            / *#/
          )),
        ] of Mode
      )

      number = Mode.new.apply(
        class_name: "number",
        relevance: 0,
        variants: [
          # Float
          Mode.new.apply(begin: /\b\d[\d_]*((\.[\d_]+(E[+-]?[\d_]+)?)|(E[+-]?[\d_]+))[RFD@!#]?/),
          # Integer (base 10)
          Mode.new.apply(begin: /\b\d[\d_]*((U?[SIL])|[%&])?/),
          # Integer (base 16)
          Mode.new.apply(begin: /&H[\dA-F_]+((U?[SIL])|[%&])?/),
          # Integer (base 8)
          Mode.new.apply(begin: /&O[0-7_]+((U?[SIL])|[%&])?/),
          # Integer (base 2)
          Mode.new.apply(begin: /&B[01_]+((U?[SIL])|[%&])?/),
        ] of Mode
      )

      label = Mode.new.apply(
        class_name: "label",
        begin: /^\w+:/
      )

      doc_comment = hljs.comment(/'''/, /$/, Mode.new.apply(contains: [
        Mode.new.apply(
          class_name: "doctag",
          begin: /<\/?/,
          end: />/
        ),
      ] of Mode))

      comment = hljs.comment(nil, /$/, Mode.new.apply(variants: [
        Mode.new.apply(begin: /'/),
        Mode.new.apply(
          # TODO: Use multi-class for leading spaces
          begin: /([\t ]|^)REM(?=\s)/
        ),
      ] of Mode))

      directives = Mode.new.apply(
        class_name: "meta",
        # TODO: Use multi-class for indentation once available
        begin: /[\t ]*#(const|disable|else|elseif|enable|end|externalsource|if|region)\b/,
        end: /$/,
        keywords: {"keyword" => "const disable else elseif enable end externalsource if region then"} of String => KeywordsVal,
        contains: [comment] of Mode
      )

      keywords = {} of String => KeywordsVal
      keywords["keyword"] =
        "addhandler alias aggregate ansi as async assembly auto binary by byref byval " + # a-b
        "call case catch class compare const continue custom declare default delegate dim distinct do " + # c-d
        "each equals else elseif end enum erase error event exit explicit finally for friend from function " + # e-f
        "get global goto group handles if implements imports in inherits interface into iterator " + # g-i
        "join key let lib loop me mid module mustinherit mustoverride mybase myclass " + # j-m
        "namespace narrowing new next notinheritable notoverridable " + # n
        "of off on operator option optional order overloads overridable overrides " + # o
        "paramarray partial preserve private property protected public " + # p
        "raiseevent readonly redim removehandler resume return " + # r
        "select set shadows shared skip static step stop structure strict sub synclock " + # s
        "take text then throw to try unicode until using when where while widening with withevents writeonly yield" # t-y
      keywords["built_in"] =
        # Operators https://docs.microsoft.com/dotnet/visual-basic/language-reference/operators
        "addressof and andalso await directcast gettype getxmlnamespace is isfalse isnot istrue like mod nameof new not or orelse trycast typeof xor " +
        # Type Conversion Functions https://docs.microsoft.com/dotnet/visual-basic/language-reference/functions/type-conversion-functions
        "cbool cbyte cchar cdate cdbl cdec cint clng cobj csbyte cshort csng cstr cuint culng cushort"
      keywords["type"] =
        # Data types https://docs.microsoft.com/dotnet/visual-basic/language-reference/data-types
        "boolean byte char date decimal double integer long object sbyte short single string uinteger ulong ushort"
      keywords["literal"] = "true false nothing"

      Mode.new.apply(
        name: "Visual Basic .NET",
        aliases: ["vb"],
        case_insensitive: true,
        class_name_aliases: {"label" => "symbol"},
        keywords: keywords,
        illegal: "//|\\{|\\}|endif|gosub|variant|wend|^\\$ ", # reserved deprecated keywords
        contains: [
          character,
          string_mode,
          date_mode,
          number,
          label,
          doc_comment,
          comment,
          directives,
        ] of Mode
      )
    end
  end

  Languages.register("vbnet", ->(hljs : HLJS) { Vbnet.defined(hljs) })
end
