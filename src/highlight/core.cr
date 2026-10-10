# Порт lib/core.js (highlight.js 11.12.0): компиляция языков/режимов,
# MultiRegex/ResumableMultiRegex, движок _highlight, highlightAuto и
# публичный API HLJS. DOM-части (highlightElement/highlightAll) не портированы.

module Highlight
  class IllegalError < Exception
    property mode : Mode?

    def initialize(message, @mode = nil)
      super(message)
    end
  end

  class MultiClassError < Exception
    def initialize(msg = "Multiclass error")
      super(msg)
    end
  end

  class UnknownLanguageError < Exception
  end

  COMMON_KEYWORDS = ["of", "and", "for", "in", "not", "or", "if", "then", "parent", "list", "value"]
  DEFAULT_KEYWORD_SCOPE = "keyword"
  MAX_KEYWORD_HITS = 7
  VERSION = "11.12.0"

  def self.compile_keywords(raw_keywords : KeywordsVal, case_insensitive : Bool, scope_name : String = DEFAULT_KEYWORD_SCOPE) : MatchGroups
    compiled = {} of String => Tuple(String, Int32)

    case raw_keywords
    when String
      compile_keyword_list(compiled, scope_name, raw_keywords.split(" "), case_insensitive)
    when Array(String)
      compile_keyword_list(compiled, scope_name, raw_keywords, case_insensitive)
    when Hash(String, KeywordsVal)
      raw_keywords.each do |sub_scope, sub|
        compiled.merge!(compile_keywords(sub, case_insensitive, sub_scope))
      end
    end

    compiled
  end

  private def self.compile_keyword_list(compiled, scope_name, keyword_list : Array(String), case_insensitive)
    keyword_list = keyword_list.map(&.downcase) if case_insensitive
    keyword_list.each do |keyword|
      pair = keyword.split("|")
      compiled[pair[0]] = {scope_name, score_for_keyword(pair[0], pair[1]?)}
    end
  end

  private def self.score_for_keyword(keyword : String, provided_score : String?) : Int32
    return provided_score.not_nil!.to_i if provided_score
    common_keyword(keyword) ? 0 : 1
  end

  private def self.common_keyword(keyword : String) : Bool
    COMMON_KEYWORDS.includes?(keyword.downcase)
  end

  # --- MultiRegex ----------------------------------------------------------

  class MultiRegex
    struct RuleOpts
      property rule : Mode?
      property type : String?
      property position : Int32 = 0

      def initialize(@rule = nil, @type = nil)
      end
    end

    @match_indexes = {} of Int32 => RuleOpts
    @regexes = [] of {RuleOpts, String}
    @match_at = 1
    @position = 0
    @matcher_re : JSRe? = nil
    @compiler : LanguageCompiler
    property last_index : Int32 = 0

    def initialize(@compiler)
    end

    def add_rule(re : Pattern, opts : RuleOpts)
      opts.position = @position
      @position += 1
      @match_indexes[@match_at] = opts
      @regexes << {opts, RegexHelpers.source(re).to_s}
      @match_at += JSRegex.count_match_groups(RegexHelpers.source(re).to_s) + 1
    end

    def compile
      return if @regexes.empty?
      terminators = @regexes.map { |el| el[1] }
      @matcher_re = @compiler.lang_re(JSRegex.rewrite_backreferences(terminators, join_with: "|"))
    end

    def exec(s : String) : EnhancedMatch?
      re = @matcher_re
      return nil if re.nil?
      re.last_index = @last_index
      md = re.exec(s)
      return nil if md.nil?

      i = (1...md.size).find { |g| !md[g]?.nil? } || return nil
      match_data = @match_indexes[i]?

      m = EnhancedMatch.new
      m.index = md.byte_begin(0).not_nil!
      m.text = md[0]
      m.input = s
      m.groups = (i + 1...md.size).map { |g| md[g]? }
      if match_data
        m.rule = match_data.rule
        m.type = match_data.type
        m.position = match_data.position
      end
      m
    end
  end

  # --- ResumableMultiRegex --------------------------------------------------

  class ResumableMultiRegex
    @rules = [] of {String, MultiRegex::RuleOpts}
    @multi_regexes = [] of MultiRegex?
    @count = 0
    property last_index : Int32 = 0
    property regex_index : Int32 = 0
    @compiler : LanguageCompiler

    def initialize(@compiler)
    end

    def get_matcher(index : Int32) : MultiRegex
      if index < @multi_regexes.size && (m = @multi_regexes[index]?)
        return m
      end
      matcher = MultiRegex.new(@compiler)
      @rules[index..].each { |(re, opts)| matcher.add_rule(re, opts) }
      matcher.compile
      while @multi_regexes.size <= index
        @multi_regexes << nil
      end
      @multi_regexes[index] = matcher
      matcher
    end

    def resuming_scan_at_same_position? : Bool
      regex_index != 0
    end

    def consider_all
      @regex_index = 0
    end

    def add_rule(re : Pattern, opts : MultiRegex::RuleOpts)
      src = RegexHelpers.source(re).to_s
      @rules << {src, opts}
      @count += 1 if opts.type == "begin"
    end

    def exec(s : String) : EnhancedMatch?
      m = get_matcher(@regex_index)
      m.last_index = last_index
      result = m.exec(s)

      if resuming_scan_at_same_position?
        if result && result.index == last_index
          # совпадение в текущей позиции — оставляем
        else
          m2 = get_matcher(0)
          m2.last_index = JSRe.char_advance(s, last_index)
          result = m2.exec(s)
        end
      end

      if result
        @regex_index += result.position + 1
        consider_all if @regex_index == @count
      end

      result
    end
  end

  # --- Компиляция языка/режимов ----------------------------------------------

  class LanguageCompiler
    getter language : Mode

    def initialize(@language : Mode)
      @language.compiler_extensions ||= [] of CompilerExt
    end

    def lang_re(value : Pattern) : JSRe
      JSRe.new(RegexHelpers.source(value).not_nil!, @language.case_insensitive == true)
    end

    def compile_language : Mode
      if @language.contains && @language.contains.not_nil!.any?(&.same?(Mode.self_marker))
        raise ArgumentError.new("ERR: contains `self` is not supported at the top-level of a language.  See documentation.")
      end

      # null-объект для classNameAliases
      @language.class_name_aliases ||= {} of String => String

      compile_mode(@language, nil)
    end

    def compile_mode(mode : Mode, parent : Mode?) : Mode
      return mode if mode.is_compiled?

      scope_class_name(mode)
      compile_match(mode)
      multi_class(mode)
      before_match_ext(mode)

      @language.compiler_extensions.not_nil!.each { |ext| ext.call(mode, parent) }

      mode.before_begin = nil

      begin_keywords(mode, parent)
      compile_illegal(mode, parent)
      compile_relevance(mode, parent)

      mode.is_compiled = true

      keyword_pattern : String? = nil
      if mode.keywords.is_a?(Hash(String, KeywordsVal))
        kw = mode.keywords.as(Hash(String, KeywordsVal))
        if kw.has_key?("$pattern")
          # копия: keywords могут компилироваться несколько раз
          kw2 = kw.dup
          keyword_pattern = kw2["$pattern"].as?(String)
          kw2.delete("$pattern")
          mode.keywords = kw2
        end
      end
      keyword_pattern ||= "\\w+"

      if mode.keywords
        mode.keywords_compiled = Highlight.compile_keywords(mode.keywords.not_nil!, @language.case_insensitive == true)
      end

      mode.keyword_pattern_re = lang_re(keyword_pattern)

      if parent
        mode.begin = /\B|\b/ unless mode.begin
        mode.begin_re = lang_re(mode.begin.not_nil!)
        # JS falsy: end === undefined ИЛИ end === ''
        if (mode.end.nil? || mode.end == "") && !mode.ends_with_parent
          mode.end = /\B|\b/
        end
        mode.end_re = lang_re(mode.end.not_nil!) if mode.end
        mode.terminator_end = RegexHelpers.source(mode.end) || ""
        if mode.ends_with_parent && parent.terminator_end
          mode.terminator_end = mode.terminator_end.to_s + (mode.end ? "|" : "") + parent.terminator_end.to_s
        end
      end
      if ilegal = mode.illegal
        mode.illegal_re = lang_re(ilegal)
      end
      mode.contains ||= [] of Mode

      expanded = [] of Mode
      mode.contains.not_nil!.each do |c|
        item = c.same?(Mode.self_marker) ? mode : c
        expand_or_clone_mode(item).each { |m| expanded << m }
      end
      mode.contains = expanded
      mode.contains.not_nil!.each { |c| compile_mode(c, mode) }

      if starts = mode.starts
        compile_mode(starts, parent)
      end

      mode.matcher = build_mode_regex(mode)
      mode
    end

    def build_mode_regex(mode : Mode) : ResumableMultiRegex
      mm = ResumableMultiRegex.new(self)
      mode.contains.not_nil!.each do |term|
        mm.add_rule(term.begin.not_nil!, MultiRegex::RuleOpts.new(rule: term, type: "begin"))
      end
      if te = mode.terminator_end
        mm.add_rule(te, MultiRegex::RuleOpts.new(type: "end")) unless te.empty?
      end
      if ill = mode.illegal
        mm.add_rule(ill, MultiRegex::RuleOpts.new(type: "illegal"))
      end
      mm
    end

    def dependency_on_parent(mode : Mode?) : Bool
      return false if mode.nil?
      mode.ends_with_parent == true || dependency_on_parent(mode.starts)
    end

    def expand_or_clone_mode(mode : Mode) : Array(Mode)
      if mode.variants && !mode.cached_variants
        mode.cached_variants = mode.variants.not_nil!.map do |variant|
          m = mode.inherit(clear_variants: true)
          m.copy_from(variant)
          m
        end
      end

      return mode.cached_variants.not_nil! if mode.cached_variants

      if dependency_on_parent(mode)
        starts_copy = mode.starts ? mode.starts.not_nil!.dup_shallow : nil
        return [mode.inherit(clear_starts: true).tap { |m| m.starts = starts_copy }]
      end

      if mode.frozen_content?
        return [mode.inherit]
      end

      [mode]
    end

    # --- compiler extensions ---

    private def scope_class_name(mode)
      if cn = mode.class_name
        mode.scope = cn
        mode.class_name = nil
      end
    end

    private def compile_match(mode)
      return unless mode.match
      if mode.begin || mode.end
        raise ArgumentError.new("begin & end are not supported with match")
      end
      mode.begin = mode.match
      mode.match = nil
    end

    private def begin_keywords(mode, parent)
      return if parent.nil?
      return unless mode.begin_keywords

      bks = mode.begin_keywords.not_nil!
      mode.begin = "\\b(" + bks.split(" ").join("|") + ")(?!\\.)(?=\\b|\\s)"
      mode.before_begin = ->(match : EnhancedMatch, response : Response) {
        before_char = match.index > 0 ? match.input.byte_at?(match.index - 1) : nil
        response.ignore_match if before_char == '.'.ord
        nil
      }
      mode.keywords = mode.keywords || bks
      mode.relevance = 0 if mode.relevance.nil?
    end

    private def compile_illegal(mode, parent)
      case illegal = mode.illegal
      when Array
        mode.illegal = RegexHelpers.either(illegal.map { |x| x.is_a?(Regex) ? x : x.as(String) })
      end
    end

    private def compile_relevance(mode, parent)
      mode.relevance = 1 if mode.relevance.nil?
    end

    private def before_match_ext(mode)
      return unless mode.before_match
      raise ArgumentError.new("beforeMatch cannot be used with starts") if mode.starts

      original = mode.dup_shallow
      original.before_match = nil

      # очистить режим (Object.keys(mode).forEach delete)
      clear_mode(mode)

      mode.keywords = original.keywords
      mode.begin = RegexHelpers.concat(original.before_match.not_nil!.as(String | Regex), RegexHelpers.lookahead(original.begin.not_nil!.as(String | Regex)))
      starts = Mode.new
      starts.relevance = 0
      starts.contains = [original.dup_shallow.tap { |sm| sm.ends_parent = true }]
      mode.starts = starts
      mode.relevance = 0
    end

    private def clear_mode(mode : Mode)
      {% for f in Mode.instance_vars %}
        {% if f.name != "frozen_content" && f.name != "is_compiled" %}
          mode.{{f.name.id}} = nil
        {% end %}
      {% end %}
      mode.is_compiled = false
    end

    # --- MultiClass ---

    private def scope_sugar(mode)
      if mode.scope.is_a?(Hash(String, String))
        mode.begin_scope = mode.scope
        mode.scope = nil
      end
    end

    private def multi_class(mode)
      scope_sugar(mode)

      if mode.begin_scope.is_a?(String)
        mode.begin_scope = {"_wrap" => mode.begin_scope.as(String)}
      end
      if mode.end_scope.is_a?(String)
        mode.end_scope = {"_wrap" => mode.end_scope.as(String)}
      end

      begin_multi_class(mode)
      end_multi_class(mode)
    end

    private def begin_multi_class(mode)
      return unless mode.begin.is_a?(Array)
      arr = mode.begin.as(Array(String | Regex))

      if mode.skip || mode.exclude_begin || mode.return_begin
        raise MultiClassError.new("skip, excludeBegin, returnBegin not compatible with beginScope: {}")
      end
      unless mode.begin_scope.is_a?(Hash(String, String))
        raise MultiClassError.new("beginScope must be object")
      end

      srcs = arr.map { |x| x.is_a?(Regex) ? x.source : x }
      mode.begin_scope = remap_scope_names(mode, srcs, :begin_scope)
      mode.begin = JSRegex.rewrite_backreferences(srcs, join_with: "")
    end

    private def end_multi_class(mode)
      return unless mode.end.is_a?(Array)
      arr = mode.end.as(Array(String | Regex))

      if mode.skip || mode.exclude_end || mode.return_end
        raise MultiClassError.new("skip, excludeEnd, returnEnd not compatible with endScope: {}")
      end
      unless mode.end_scope.is_a?(Hash(String, String))
        raise MultiClassError.new("endScope must be object")
      end

      srcs = arr.map { |x| x.is_a?(Regex) ? x.source : x }
      mode.end_scope = remap_scope_names(mode, srcs, :end_scope)
      mode.end = JSRegex.rewrite_backreferences(srcs, join_with: "")
    end

    private def remap_scope_names(mode, regexes : Array(String), key : Symbol) : CompiledScope
      scope_names = key == :begin_scope \
        ? mode.begin_scope.as(Hash(String, String))
        : mode.end_scope.as(Hash(String, String))

      offset = 0
      compiled = CompiledScope.new
      emit = {} of Int32 => Bool
      positions = {} of Int32 => String

      (1..regexes.size).each do |i|
        if (name = scope_names[i.to_s]?)
          positions[i + offset] = name
        end
        emit[i + offset] = true
        offset += JSRegex.count_match_groups(regexes[i - 1])
      end
      compiled.positions = positions
      compiled.emit = emit
      compiled.multi = true
      compiled
    end
  end

  # --- Результаты -------------------------------------------------------------

  class HighlightResult
    property language : String?
    property value : String
    property relevance : Int32 | Float64
    property illegal : Bool
    property code : String?
    property second_best : HighlightResult? = nil
    property error_raised : Exception? = nil
    getter emitter : TokenTreeEmitter
    property top : Mode?

    def initialize(@language, @value, @relevance, @illegal, @emitter, @top = nil)
    end
  end

  class BeforeHighlightContext
    property code : String
    property language : String
    property result : HighlightResult?

    def initialize(@code, @language)
    end
  end

  class Plugin
    property before_highlight : Proc(BeforeHighlightContext, Nil)? = nil
    property after_highlight : Proc(HighlightResult, Nil)? = nil
    property before_highlight_element : Proc(BeforeHighlightContext, Nil)? = nil
    property after_highlight_element : Proc(HighlightResult, Nil)? = nil
  end

  # --- HLJS API ----------------------------------------------------------------

  class HLJS
    PLAINTEXT_LANGUAGE = Mode.new.apply(name: "Plain text", disable_autodetect: true, contains: [] of Mode)

    property class_prefix : String = "hljs-"
    property languages_option : Array(String)? = nil
    getter? safe_mode : Bool = true

    def initialize
      @languages = {} of String => Mode
      @aliases = {} of String => String
      @plugins = [] of Plugin
    end

    def new_instance : HLJS
      HLJS.new
    end

    def version_string : String
      VERSION
    end

    def debug_mode
      @safe_mode = false
    end

    def safe_mode
      @safe_mode = true
    end

    getter regex = RegexHelpers

    # регистрация
    def register_language(language_name : String, language_definition : Proc(HLJS, Mode))
      lang : Mode
      begin
        lang = language_definition.call(self)
      rescue ex
        raise ex unless safe_mode?
        lang = PLAINTEXT_LANGUAGE
      end
      lang.name = language_name if lang.name.nil?
      @languages[language_name] = lang
      lang.raw_definition = language_definition

      if aliases = lang.aliases
        register_aliases(aliases, language_name)
      end
    end

    def register_language(language_name : String)
      fn = Languages.language_fn(language_name)
      raise UnknownLanguageError.new("no language definition: #{language_name}") unless fn
      register_language(language_name, fn)
    end

    def unregister_language(language_name : String)
      @languages.delete(language_name)
      @aliases.keys.each do |alias_name|
        @aliases.delete(alias_name) if @aliases[alias_name] == language_name
      end
    end

    def list_languages : Array(String)
      @languages.keys
    end

    def get_language(name : String?) : Mode?
      name = (name || "").downcase
      @languages[name]? || @languages[@aliases[name]?]?
    end

    def register_aliases(alias_list : String | Array(String), language_name : String)
      alias_list = [alias_list] if alias_list.is_a?(String)
      alias_list.each { |a| @aliases[a.downcase] = language_name }
    end

    def auto_detection?(name : String) : Bool
      lang = get_language(name)
      !lang.nil? && lang.disable_autodetect != true
    end

    def add_plugin(plugin : Plugin)
      @plugins << plugin
    end

    def remove_plugin(plugin : Plugin)
      @plugins.delete(plugin)
    end

    def configure(*, class_prefix : String? = nil, languages : Array(String)? = nil,
                  ignore_unescaped_html : Bool? = nil, throw_unescaped_html : Bool? = nil)
      @class_prefix = class_prefix unless class_prefix.nil?
      @languages_option = languages unless languages.nil?
    end

    # --- highlight ---

    def highlight(code : String, language : String?, ignore_illegals : Bool = true) : HighlightResult
      context = BeforeHighlightContext.new(code, language.to_s)
      fire("before:highlight", context)

      result = context.result || _highlight(context.language, context.code, ignore_illegals, nil)
      result.code = context.code
      fire("after:highlight", result)
      result
    end

    def just_text_highlight_result(code : String) : HighlightResult
      emitter = TokenTreeEmitter.new
      emitter.add_text(code)
      HighlightResult.new(nil, Highlight.escape_html(code), 0, false, emitter, PLAINTEXT_LANGUAGE)
    end

    def highlight_auto(code : String, language_subset : Array(String)? = nil) : HighlightResult
      subset = language_subset || @languages_option || @languages.keys
      plaintext = just_text_highlight_result(code)

      results = subset
        .select { |name| get_language(name) && auto_detection?(name) }
        .map { |name| _highlight(name, code, false, nil) }
      results.unshift(plaintext)

      decorated = results.map_with_index { |r, i| {r, i} }
      sorted = decorated.sort do |(a, ai), (b, bi)|
        cmp = b.relevance <=> a.relevance
        next cmp if cmp != 0
        if a.language && b.language
          ga = get_language(a.language.not_nil!)
          gb = get_language(b.language.not_nil!)
          if ga && ga.superset_of == b.language
            next 1
          elsif gb && gb.superset_of == a.language
            next -1
          end
        end
        ai <=> bi
      end

      best = sorted[0][0]
      second = sorted[1]?.try(&.[0])
      best.second_best = second
      best
    end

    # --- приватный движок ---

    def _highlight(language_name : String, code : String, ignore_illegals : Bool, continuation : Mode?) : HighlightResult
      language = get_language(language_name)
      if language.nil?
        raise UnknownLanguageError.new("Unknown language: \"#{language_name}\"")
      end

      compiler = LanguageCompiler.new(language)
      md = compiler.compile_language

      session = HighlightSession.new(self, language_name, language, code, ignore_illegals, continuation || md)
      session.run
    rescue ex : IllegalError
      HighlightResult.new(language_name, Highlight.escape_html(code), 0, true, TokenTreeEmitter.new)
    rescue ex : UnknownLanguageError
      raise ex
    rescue ex
      if safe_mode?
        r = HighlightResult.new(language_name, Highlight.escape_html(code), 0, false, TokenTreeEmitter.new)
        r.error_raised = ex
        r
      else
        raise ex
      end
    end

    private def fire(event : String, arg : BeforeHighlightContext | HighlightResult)
      @plugins.each do |plugin|
        case event
        when "before:highlight"
          if (ctx = arg).is_a?(BeforeHighlightContext)
            plugin.before_highlight.try(&.call(ctx))
          end
        when "after:highlight"
          if (res = arg).is_a?(HighlightResult)
            plugin.after_highlight.try(&.call(res))
          end
        end
      end
    end

    # --- режимы для языков (аналог hljs.COMMENT / hljs.SHEBANG / ...) ---
    def comment(begin_p : Pattern?, end_p : Pattern?, mode_options : Mode? = nil) : Mode
      MODES.comment(begin_p, end_p, mode_options)
    end

    def shebang(*, binary : String? = nil, **opts) : Mode
      m = MODES.shebang(binary: binary)
      m.apply(**opts) unless opts.empty?
      m
    end

    def end_same_as_begin(mode : Mode) : Mode
      MODES.end_same_as_begin(mode)
    end
  end
end
