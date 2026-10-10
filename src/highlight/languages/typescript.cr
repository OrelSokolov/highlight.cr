# Порт lib/languages/typescript.js (highlight.js 11.12.0), часть после
# javascript (строки 772+): мутации поверх свежего javascript-режима.

module Highlight::Languages
  module TypescriptLang
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      ts_language = JavascriptLang.defined(hljs)

      types = [
        "any",
        "void",
        "number",
        "boolean",
        "string",
        "object",
        "never",
        "symbol",
        "bigint",
        "unknown",
      ]
      namespace = Mode.new.apply(
        begin: [
          /namespace/,
          /\s+/,
          IDENT_RE,
        ] of String | Regex,
        begin_scope: {
          "1" => "keyword",
          "3" => "title.class",
        }
      )
      interface = Mode.new.apply(
        begin_keywords: "interface",
        end: /\{/,
        exclude_end: true,
        keywords: {
          "keyword"  => "interface extends",
          "built_in" => types,
        } of String => KeywordsVal,
        contains: [ts_language.exports.not_nil!["CLASS_REFERENCE"].as(Mode)]
      )
      use_strict = Mode.new.apply(
        class_name: "meta",
        relevance: 10,
        begin: /^\s*['"]use strict['"]/
      )
      ts_specific_keywords = [
        "type",
        # "namespace",
        "interface",
        "public",
        "private",
        "protected",
        "implements",
        "declare",
        "abstract",
        "readonly",
        "enum",
        "override",
        "satisfies",
      ]
      # namespace is a TS keyword but it's fine to use it as a variable name too.
      # const message = 'foo';
      # const namespace = 'bar';
      keywords = {} of String => KeywordsVal
      keywords["$pattern"] = JavascriptLang::IDENT_RE_JS
      keywords["keyword"] = JavascriptLang::KEYWORDS_JS + ts_specific_keywords
      keywords["literal"] = JavascriptLang::LITERALS_JS
      keywords["built_in"] = JavascriptLang::BUILT_INS_JS + types
      keywords["variable.language"] = JavascriptLang::BUILT_IN_VARIABLES_JS

      decorator = Mode.new.apply(
        class_name: "meta",
        begin: "@" + JavascriptLang::IDENT_RE_JS,
      )

      # this should update anywhere keywords is used since
      # it will be the same actual object
      # (JS: Object.assign(tsLanguage.keywords, KEYWORDS$1))
      ts_language.keywords.as(Hash(String, KeywordsVal)).merge!(keywords)

      params_contains = ts_language.exports.not_nil!["PARAMS_CONTAINS"].as(Array(Mode))
      params_contains << decorator

      # highlight the function params
      attribute_highlight = ts_language.contains.not_nil!.find { |c| c.scope == "attr" }.not_nil!

      # take default attr rule and extend it to support optionals
      optional_key_or_argument = attribute_highlight.dup_shallow
      optional_key_or_argument.match = regex.concat(JavascriptLang::IDENT_RE_JS, regex.lookahead(/\s*\?:/))
      params_contains << ts_language.exports.not_nil!["CLASS_REFERENCE"].as(Mode) # class reference for highlighting the params types
      params_contains << attribute_highlight                                        # highlight the params key
      params_contains << optional_key_or_argument                                   # Added for optional property assignment highlighting

      # Add the optional property assignment highlighting for objects or classes
      ts_language.contains = ts_language.contains.not_nil! + [
        decorator,
        namespace,
        interface,
        optional_key_or_argument, # Added for optional property assignment highlighting
      ] of Mode

      # TS gets a simpler shebang rule than JS
      swap_mode(ts_language, "shebang", hljs.shebang)
      # JS use strict rule purposely excludes `asm` which makes no sense
      swap_mode(ts_language, "use_strict", use_strict)

      function_declaration = ts_language.contains.not_nil!.find { |m| m.label == "func.def" }.not_nil!
      function_declaration.relevance = 0 # () => {} is more typical in TypeScript

      ts_language.name = "TypeScript"
      ts_language.aliases = [
        "ts",
        "tsx",
        "mts",
        "cts",
      ]
      ts_language
    end

    private def self.swap_mode(mode : Mode, label : String, replacement : Mode) : Nil
      indx = mode.contains.not_nil!.index { |m| m.label == label }
      raise ArgumentError.new("can not find mode to replace") if indx.nil?
      mode.contains.not_nil![indx] = replacement
    end
  end

  Languages.register("typescript", ->(hljs : HLJS) { TypescriptLang.defined(hljs) })
end
