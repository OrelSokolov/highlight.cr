# Порт regex-хелперов (concat/either/lookahead/optional/anyNumberOfTimes)
# и общих режимов MODES из core.js. Константы «заморожены» (frozen_content),
# как deepFreeze в оригинале — expandOrCloneMode обязан их копировать.

module Highlight
  module RegexHelpers
    def self.source(re : Pattern?) : String?
      case re
      when String then re
      when Regex  then re.source
      when Array  then nil
      else             nil
      end
    end

    def self.concat(*args : (String | Regex)) : String
      args.map { |x| x.is_a?(Regex) ? x.source : x }.join
    end

    def self.concat(args : Array(String | Regex)) : String
      args.map { |x| x.is_a?(Regex) ? x.source : x }.join
    end

    def self.lookahead(re : String | Regex) : String
      concat("(?=", re, ")")
    end

    def self.any_number_of_times(re : String | Regex) : String
      concat("(?:", re, ")*")
    end

    def self.optional(re : String | Regex) : String
      concat("(?:", re, ")?")
    end

    # either(...args, {capture: true}?) — опции последним элементом,
    # как stripOptionsFromArgs в оригинале.
    def self.either(args : Array(String | Regex), capture : Bool = false) : String
      "(" + (capture ? "" : "?:") + args.map { |x| x.is_a?(Regex) ? x.source : x }.join("|") + ")"
    end
  end

  # --- Common regexps (строки как в оригинале) ---
  MATCH_NOTHING_RE    = /\b\B/
  IDENT_RE            = "[a-zA-Z]\\w*"
  UNDERSCORE_IDENT_RE = "[a-zA-Z_]\\w*"
  NUMBER_RE           = "\\b\\d+(\\.\\d+)?"
  C_NUMBER_RE         = "(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)"
  BINARY_NUMBER_RE    = "\\b(0b[01]+)"
  RE_STARTERS_RE      = "!|!=|!==|%|%=|&|&&|&=|\\*|\\*=|\\+|\\+=|,|-|-=|/=|/|:|;|<<|<<=|<=|<|===|==|=|>>>=|>>=|>=|>>>|>>|>|\\?|\\[|\\{|\\(|\\^|\\^=|\\||\\|=|\\|\\||~"

  module MODES
    # BACKSLASH_ESCAPE
    BACKSLASH_ESCAPE = Mode.frozen(
      begin: "\\\\[\\s\\S]", relevance: 0
    )

    APOS_STRING_MODE = Mode.frozen(
      scope: "string", begin: "'", end: "'", illegal: "\\n",
      contains: [BACKSLASH_ESCAPE]
    )

    QUOTE_STRING_MODE = Mode.frozen(
      scope: "string", begin: "\"", end: "\"", illegal: "\\n",
      contains: [BACKSLASH_ESCAPE]
    )

    PHRASAL_WORDS_MODE = Mode.frozen(
      begin: /\b(a|an|the|are|I'm|isn't|don't|doesn't|won't|but|just|should|pretty|simply|enough|gonna|going|wtf|so|such|will|you|your|they|like|more)\b/
    )

    NUMBER_MODE = Mode.frozen(scope: "number", begin: NUMBER_RE, relevance: 0)
    C_NUMBER_MODE = Mode.frozen(scope: "number", begin: C_NUMBER_RE, relevance: 0)
    BINARY_NUMBER_MODE = Mode.frozen(scope: "number", begin: BINARY_NUMBER_RE, relevance: 0)

    REGEXP_MODE = Mode.frozen(
      scope: "regexp",
      begin: %r(/(?=[^/\n]*/)),
      end: /\/[gimuy]*/,
      contains: [
        BACKSLASH_ESCAPE,
        Mode.frozen(begin: /\[/, end: /\]/, relevance: 0, contains: [BACKSLASH_ESCAPE]),
      ]
    )

    TITLE_MODE = Mode.frozen(scope: "title", begin: IDENT_RE, relevance: 0)
    UNDERSCORE_TITLE_MODE = Mode.frozen(scope: "title", begin: UNDERSCORE_IDENT_RE, relevance: 0)
    METHOD_GUARD = Mode.frozen(begin: "\\.\\s*" + UNDERSCORE_IDENT_RE, relevance: 0)

    C_LINE_COMMENT_MODE = comment("//", "$")
    C_BLOCK_COMMENT_MODE = comment("/\\*", "\\*/")
    HASH_COMMENT_MODE = comment("#", "$")

    # COMMENT(begin, end, modeOptions) — begin/end могут быть nil (hljs.COMMENT())
    def self.comment(begin_p : Pattern?, end_p : Pattern?, mode_options : Mode? = nil) : Mode
      mode = Mode.new.apply(scope: "comment", begin: begin_p, end: end_p, contains: [] of Mode)
      mode.copy_from(mode_options) if mode_options
      mode.contains.not_nil! << Mode.new.apply(
        scope: "doctag",
        begin: "[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)",
        end: /(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):/,
        exclude_begin: true,
        relevance: 0
      )

      english_word = RegexHelpers.either([
        "I", "a", "is", "so", "us", "to", "at", "if", "in", "it", "on",
        /[A-Za-z]+['](d|ve|re|ll|t|s|n)/,
        /[A-Za-z]+[-][a-z]+/,
        /[A-Za-z][a-z]{2,}/,
      ])

      mode.contains.not_nil! << Mode.new.apply(
        begin: RegexHelpers.concat([/[ ]+/, "(", english_word, /[.]?[:]?([.][ ]|[ ])/, "){3}"])
      )

      mode
    end

    def self.shebang(*, binary : String? = nil, **opts) : Mode
      base = Mode.new.apply(
        scope: "meta",
        begin: /^#![ ]*\//,
        end: /$/,
        relevance: 0,
        on_begin: ->(m : EnhancedMatch, resp : Response) {
          resp.ignore_match if m.index != 0
          nil
        }
      )
      if binary
        base.begin = RegexHelpers.concat(/^#![ ]*\//, /.*\b/, binary, /\b.*/)
      end
      base.apply(**opts)
      base
    end

    # END_SAME_AS_BEGIN(mode)
    def self.end_same_as_begin(mode : Mode) : Mode
      mode.on_begin = ->(m : EnhancedMatch, resp : Response) {
        resp.data["_beginMatch"] = m[1].to_s
        nil
      }
      mode.on_end = ->(m : EnhancedMatch, resp : Response) {
        resp.ignore_match if resp.data["_beginMatch"]? != m[1]
        nil
      }
      mode
    end

    # доступ «как в hljs.C_LINE_COMMENT_MODE» для языков
    def self.[](name : Symbol)
      {% begin %}
      case name
      when :apos_string_mode then APOS_STRING_MODE
      when :backslash_escape then BACKSLASH_ESCAPE
      when :binary_number_mode then BINARY_NUMBER_MODE
      when :binary_number_re then BINARY_NUMBER_RE
      when :c_block_comment_mode then C_BLOCK_COMMENT_MODE
      when :c_line_comment_mode then C_LINE_COMMENT_MODE
      when :c_number_mode then C_NUMBER_MODE
      when :c_number_re then C_NUMBER_RE
      when :hash_comment_mode then HASH_COMMENT_MODE
      when :ident_re then IDENT_RE
      when :match_nothing_re then MATCH_NOTHING_RE
      when :method_guard then METHOD_GUARD
      when :number_mode then NUMBER_MODE
      when :number_re then NUMBER_RE
      when :phrasal_words_mode then PHRASAL_WORDS_MODE
      when :quote_string_mode then QUOTE_STRING_MODE
      when :regexp_mode then REGEXP_MODE
      when :re_starters_re then RE_STARTERS_RE
      when :title_mode then TITLE_MODE
      when :underscore_ident_re then UNDERSCORE_IDENT_RE
      when :underscore_title_mode then UNDERSCORE_TITLE_MODE
      else raise KeyError.new("unknown MODES: #{name}")
      end
      {% end %}
    end
  end
end
