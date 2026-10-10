# Порт lib/languages/objectivec.js (highlight.js 11.12.0).

module Highlight::Languages
  module Objectivec
    def self.defined(hljs : HLJS) : Mode
      api_class = Mode.new.apply(
        class_name: "built_in",
        begin: "\\b(AV|CA|CF|CG|CI|CL|CM|CN|CT|MK|MP|MTK|MTL|NS|SCN|SK|UI|WK|XC)\\w+"
      )
      identifier_re = /[a-zA-Z@][a-zA-Z0-9_]*/
      types = [
        "int",
        "float",
        "char",
        "unsigned",
        "signed",
        "short",
        "long",
        "double",
        "wchar_t",
        "unichar",
        "void",
        "bool",
        "BOOL",
        "id|0",
        "_Bool",
      ]
      kws = [
        "while",
        "export",
        "sizeof",
        "typedef",
        "const",
        "struct",
        "for",
        "union",
        "volatile",
        "static",
        "mutable",
        "if",
        "do",
        "return",
        "goto",
        "enum",
        "else",
        "break",
        "extern",
        "asm",
        "case",
        "default",
        "register",
        "explicit",
        "typename",
        "switch",
        "continue",
        "inline",
        "readonly",
        "assign",
        "readwrite",
        "self",
        "@synchronized",
        "id",
        "typeof",
        "nonatomic",
        "IBOutlet",
        "IBAction",
        "strong",
        "weak",
        "copy",
        "in",
        "out",
        "inout",
        "bycopy",
        "byref",
        "oneway",
        "__strong",
        "__weak",
        "__block",
        "__autoreleasing",
        "@private",
        "@protected",
        "@public",
        "@try",
        "@property",
        "@end",
        "@throw",
        "@catch",
        "@finally",
        "@autoreleasepool",
        "@synthesize",
        "@dynamic",
        "@selector",
        "@optional",
        "@required",
        "@encode",
        "@package",
        "@import",
        "@defs",
        "@compatibility_alias",
        "__bridge",
        "__bridge_transfer",
        "__bridge_retained",
        "__bridge_retain",
        "__covariant",
        "__contravariant",
        "__kindof",
        "_Nonnull",
        "_Nullable",
        "_Null_unspecified",
        "__FUNCTION__",
        "__PRETTY_FUNCTION__",
        "__attribute__",
        "getter",
        "setter",
        "retain",
        "unsafe_unretained",
        "nonnull",
        "nullable",
        "null_unspecified",
        "null_resettable",
        "class",
        "instancetype",
        "NS_DESIGNATED_INITIALIZER",
        "NS_UNAVAILABLE",
        "NS_REQUIRES_SUPER",
        "NS_RETURNS_INNER_POINTER",
        "NS_INLINE",
        "NS_AVAILABLE",
        "NS_DEPRECATED",
        "NS_ENUM",
        "NS_OPTIONS",
        "NS_SWIFT_UNAVAILABLE",
        "NS_ASSUME_NONNULL_BEGIN",
        "NS_ASSUME_NONNULL_END",
        "NS_REFINED_FOR_SWIFT",
        "NS_SWIFT_NAME",
        "NS_SWIFT_NOTHROW",
        "NS_DURING",
        "NS_HANDLER",
        "NS_ENDHANDLER",
        "NS_VALUERETURN",
        "NS_VOIDRETURN",
      ]
      literals = [
        "false",
        "true",
        "FALSE",
        "TRUE",
        "nil",
        "YES",
        "NO",
        "NULL",
      ]
      built_ins = [
        "dispatch_once_t",
        "dispatch_queue_t",
        "dispatch_sync",
        "dispatch_async",
        "dispatch_once",
      ]
      keywords = {} of String => KeywordsVal
      keywords["variable.language"] = [
        "this",
        "super",
      ]
      keywords["$pattern"] = identifier_re.source
      keywords["keyword"] = kws
      keywords["literal"] = literals
      keywords["built_in"] = built_ins
      keywords["type"] = types
      class_keywords = {
        "$pattern" => identifier_re.source,
        "keyword"  => [
          "@interface",
          "@class",
          "@protocol",
          "@implementation",
        ],
      } of String => KeywordsVal
      class_keyword_names = class_keywords["keyword"].as(Array(String)).join("|")
      Mode.new.apply(
        name: "Objective-C",
        aliases: [
          "mm",
          "objc",
          "obj-c",
          "obj-c++",
          "objective-c++",
        ],
        keywords: keywords,
        illegal: "</",
        contains: [
          api_class,
          MODES::C_LINE_COMMENT_MODE,
          MODES::C_BLOCK_COMMENT_MODE,
          MODES::C_NUMBER_MODE,
          MODES::QUOTE_STRING_MODE,
          MODES::APOS_STRING_MODE,
          Mode.new.apply(
            class_name: "string",
            variants: [
              Mode.new.apply(
                begin: "@\"",
                end: "\"",
                illegal: "\\n",
                contains: [MODES::BACKSLASH_ESCAPE] of Mode
              ),
            ] of Mode
          ),
          Mode.new.apply(
            class_name: "meta",
            begin: /#\s*[a-z]+\b/,
            end: /$/,
            keywords: {"keyword" => "if else elif endif define undef warning error line " +
                                   "pragma ifdef ifndef include"} of String => KeywordsVal,
            contains: [
              Mode.new.apply(
                begin: /\\\n/,
                relevance: 0
              ),
              MODES::QUOTE_STRING_MODE.inherit(Mode.new.apply(class_name: "string")),
              Mode.new.apply(
                class_name: "string",
                begin: /<.*?>/,
                end: /$/,
                illegal: "\\n"
              ),
              MODES::C_LINE_COMMENT_MODE,
              MODES::C_BLOCK_COMMENT_MODE,
            ] of Mode
          ),
          Mode.new.apply(
            class_name: "class",
            begin: "(" + class_keyword_names + ")\\b",
            end: /(\{|$)/,
            exclude_end: true,
            keywords: class_keywords,
            contains: [MODES::UNDERSCORE_TITLE_MODE] of Mode
          ),
          Mode.new.apply(
            begin: "\\." + UNDERSCORE_IDENT_RE,
            relevance: 0
          ),
        ] of Mode
      )
    end
  end

  Languages.register("objectivec", ->(hljs : HLJS) { Objectivec.defined(hljs) })
end
