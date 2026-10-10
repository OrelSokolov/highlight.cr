# Порт lib/languages/makefile.js (highlight.js 11.12.0).

module Highlight::Languages
  module Makefile
    def self.defined(hljs : HLJS) : Mode
      # Variables: simple (eg $(var)) and special (eg $@)
      variable = Mode.new.apply(
        class_name: "variable",
        variants: [
          Mode.new.apply(
            begin: "\\$\\(" + UNDERSCORE_IDENT_RE + "\\)",
            contains: [MODES::BACKSLASH_ESCAPE] of Mode
          ),
          Mode.new.apply(begin: /\$[@%<?\^\+\*]/),
        ] of Mode
      )
      # Quoted string with variables inside
      quote_string = Mode.new.apply(
        class_name: "string",
        begin: /"/,
        end: /"/,
        contains: [
          MODES::BACKSLASH_ESCAPE,
          variable,
        ] of Mode
      )
      # Function: $(func arg,...)
      func = Mode.new.apply(
        class_name: "variable",
        begin: /\$\([\w-]+\s/,
        end: /\)/,
        keywords: {
          "built_in" => "subst patsubst strip findstring filter filter-out sort " +
                        "word wordlist firstword lastword dir notdir suffix basename " +
                        "addsuffix addprefix join wildcard realpath abspath error warning " +
                        "shell origin flavor foreach if or and call eval file value",
        } of String => KeywordsVal,
        contains: [
          variable,
          quote_string, # Added QUOTE_STRING as they can be a part of functions
        ] of Mode
      )
      # Variable assignment
      assignment = Mode.new.apply(begin: "^" + UNDERSCORE_IDENT_RE + "\\s*(?=[:+?]?=)")
      # Meta targets (.PHONY)
      meta = Mode.new.apply(
        class_name: "meta",
        begin: /^\.PHONY:/,
        end: /$/,
        keywords: {
          "$pattern" => "[\\.\\w]+",
          "keyword"  => ".PHONY",
        } of String => KeywordsVal
      )
      # Targets
      target = Mode.new.apply(
        class_name: "section",
        begin: /^[^\s]+:/,
        end: /$/,
        contains: [variable] of Mode
      )
      Mode.new.apply(
        name: "Makefile",
        aliases: [
          "mk",
          "mak",
          "make",
        ],
        keywords: {
          "$pattern" => "[\\w-]+",
          "keyword"  => "define endef undefine ifdef ifndef ifeq ifneq else endif " +
                        "include -include sinclude override export unexport private vpath",
        } of String => KeywordsVal,
        contains: [
          MODES::HASH_COMMENT_MODE,
          variable,
          quote_string,
          func,
          assignment,
          meta,
          target,
        ] of Mode
      )
    end
  end

  Languages.register("makefile", ->(hljs : HLJS) { Makefile.defined(hljs) })
end
