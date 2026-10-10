# Порт замыканий _highlight из core.js: processLexeme/doBeginMatch/
# doEndMatch/processKeywords/processSubLanguage + главный цикл.

module Highlight
  NO_MATCH = -1

  class HighlightSession
    @last_match : EnhancedMatch? = nil
    @top : Mode? = nil

    def initialize(@hljs : HLJS, @language_name : String, @language : Mode,
                   @code : String, @ignore_illegals : Bool, top : Mode)
      @top = top
      @emitter = TokenTreeEmitter.new
      @mode_buffer = ""
      @relevance = 0.0
      @index = 0
      @iterations = 0
      @resume_scan_at_same_position = false
      @keyword_hits = {} of String => Int32
      @continuations = {} of String => Mode
    end

    private def top! : Mode
      @top.not_nil!
    end

    # Срез от байтового индекса до конца (пустая строка за пределами)
    private def byte_from(s : String, start : Int32) : String
      return "" if start >= s.bytesize
      s.byte_slice(start)
    end

    def run : HighlightResult
      process_continuations

      top!.matcher.not_nil!.consider_all

      loop do
        @iterations += 1
        if @resume_scan_at_same_position
          @resume_scan_at_same_position = false
        else
          top!.matcher.not_nil!.consider_all
        end
        top!.matcher.not_nil!.last_index = @index

        match = top!.matcher.not_nil!.exec(@code)
        break if match.nil?
        if ENV["HLJS_TRACE"]?
          STDERR.puts "MATCH type=#{match.type} idx=#{match.index} text=#{match.text.inspect} top=#{top!.object_id}"
        end

        before_match = match.index > @index ? @code.byte_slice(@index, match.index - @index) : ""
        processed_count = process_lexeme(before_match, match)
        @index = match.index + processed_count
      end
      process_lexeme(byte_from(@code, @index), nil)

      @emitter.finalize
      html = @emitter.to_html(@hljs.class_prefix)
      HighlightResult.new(@language_name, html, js_number(@relevance), false, @emitter, @top)
    end

    # JS Number#toString: целые значения печатаются без дробной части.
    private def js_number(v : Float64) : Int32 | Float64
      if v == v.trunc && v >= Int32::MIN.to_f64 && v <= Int32::MAX.to_f64
        v.to_i32
      else
        v
      end
    end

    private def class_alias(kind : String) : String
      aliases = @language.class_name_aliases
      (aliases && aliases[kind]?) || kind
    end

    private def scope_wrap?(sc : ScopeVal) : String?
      case sc
      when CompiledScope then sc.wrap
      when Hash(String, String) then sc["_wrap"]?
      else nil
      end
    end

    private def scope_multi?(sc : ScopeVal) : Bool
      case sc
      when CompiledScope then sc.multi?
      when Hash(String, String) then sc["_multi"]? == "1" || sc["_multi"]? == "true"
      else false
      end
    end

    # --- буфер/ключевые слова ---

    private def keyword_data(mode : Mode, word : String) : Tuple(String, Int32)?
      mode.keywords_compiled.try(&.[word]?)
    end

    private def process_keywords
      top = top!
      if top.keywords_compiled.nil?
        @emitter.add_text(@mode_buffer)
        return
      end

      kpr = top.keyword_pattern_re.not_nil!
      last_index = 0
      kpr.last_index = 0
      md = kpr.exec(@mode_buffer)
      buf = ""

      while md
        buf += @mode_buffer.byte_slice?(last_index, md.byte_begin(0).not_nil! - last_index) || ""
        word0 = md[0].not_nil!
        word = @language.case_insensitive == true ? word0.downcase : word0
        if (data = keyword_data(top, word))
          kind, keyword_relevance = data
          @emitter.add_text(buf)
          buf = ""

          hits = (@keyword_hits[word]? || 0) + 1
          @keyword_hits[word] = hits
          @relevance += keyword_relevance if hits <= MAX_KEYWORD_HITS
          if kind.starts_with?("_")
            # только relevance, без класса
            buf += word0
          else
            emit_keyword(word0, class_alias(kind))
          end
        else
          buf += word0
        end
        last_index = kpr.last_index
        md = kpr.exec(@mode_buffer)
      end
      buf += byte_from(@mode_buffer, last_index)
      @emitter.add_text(buf)
    end

    private def process_sub_language
      return if @mode_buffer == ""
      result : HighlightResult? = nil
      top = top!

      case sub = top.sub_language
      when String
        if @hljs.get_language(sub).nil?
          @emitter.add_text(@mode_buffer)
          return
        end
        result = @hljs._highlight(sub, @mode_buffer, true, @continuations[sub]?)
        if (t = result.top)
          @continuations[sub] = t
        end
      when Array(String)
        result = @hljs.highlight_auto(@mode_buffer, sub.empty? ? nil : sub)
      end

      r = result.not_nil!
      @relevance += r.relevance if (top.relevance || 0) > 0
      @emitter.add_sublanguage(r.emitter, r.language)
    end

    private def process_buffer
      if !top!.sub_language.nil?
        process_sub_language
      else
        process_keywords
      end
      @mode_buffer = ""
    end

    private def emit_keyword(keyword : String, scope : String)
      return if keyword == ""
      @emitter.start_scope(scope)
      @emitter.add_text(keyword)
      @emitter.end_scope
    end

    private def emit_multi_class(scope : CompiledScope, match : EnhancedMatch)
      i = 1
      max = match.groups.size
      while i <= max
        unless scope.emit?(i)
          i += 1
          next
        end
        klass_name = scope.positions[i]?
        text = match[i].to_s
        if klass_name
          emit_keyword(text, class_alias(klass_name))
        else
          @mode_buffer = text
          process_keywords
          @mode_buffer = ""
        end
        i += 1
      end
    end

    # --- режимы ---

    private def start_new_mode(mode : Mode, match : EnhancedMatch)
      if (scope = mode.scope).is_a?(String) && !scope.empty?
        @emitter.open_node(class_alias(scope))
      end
      if bs = mode.begin_scope
        if (w = scope_wrap?(bs))
          emit_keyword(@mode_buffer, class_alias(w))
          @mode_buffer = ""
        elsif scope_multi?(bs)
          emit_multi_class(bs.as(CompiledScope), match)
          @mode_buffer = ""
        end
      end

      @top = mode.derive(@top)
    end

    private def end_of_mode(mode : Mode, match : EnhancedMatch, match_plus_remainder : String) : Mode?
      matched = starts_with_end(mode, match_plus_remainder)

      if matched
        if cb = mode.on_end
          resp = Response.new(mode)
          cb.call(match, resp)
          matched = false if resp.is_match_ignored?
        end

        if matched
          while mode.ends_parent == true && mode.parent
            mode = mode.parent.not_nil!
          end
          return mode
        end
      end
      if mode.ends_with_parent == true && mode.parent
        return end_of_mode(mode.parent.not_nil!, match, match_plus_remainder)
      end
      nil
    end

    private def starts_with_end(mode : Mode, remainder : String) : Bool
      re = mode.end_re
      return false if re.nil?
      JSRe.match_starts_with(re.regex, remainder)
    end

    private def do_ignore(lexeme : String) : Int32
      if top!.matcher.not_nil!.regex_index == 0
        len = JSRe.char_bytesize_at(lexeme, 0)
        @mode_buffer += lexeme.byte_slice(0, len)
        len
      else
        @resume_scan_at_same_position = true
        0
      end
    end

    private def do_begin_match(match : EnhancedMatch) : Int32
      lexeme = match.text
      new_mode = match.rule.not_nil!

      resp = Response.new(new_mode)
      before_callbacks = [new_mode.before_begin, new_mode.on_begin]
      before_callbacks.each do |cb|
        next if cb.nil?
        cb.call(match, resp)
        return do_ignore(lexeme) if resp.is_match_ignored?
      end

      if new_mode.skip == true
        @mode_buffer += lexeme
      else
        if new_mode.exclude_begin == true
          @mode_buffer += lexeme
        end
        process_buffer
        if new_mode.return_begin != true && new_mode.exclude_begin != true
          @mode_buffer = lexeme
        end
      end
      start_new_mode(new_mode, match)
      new_mode.return_begin == true ? 0 : lexeme.bytesize
    end

    private def do_end_match(match : EnhancedMatch) : Int32
      lexeme = match.text
      match_plus_remainder = byte_from(@code, match.index)

      end_mode = end_of_mode(top!, match, match_plus_remainder)
      return NO_MATCH if end_mode.nil?

      origin = top!
      if (es = origin.end_scope) && (w = scope_wrap?(es))
        process_buffer
        emit_keyword(lexeme, class_alias(w))
      elsif (es = origin.end_scope) && scope_multi?(es)
        process_buffer
        emit_multi_class(es.as(CompiledScope), match)
      elsif origin.skip == true
        @mode_buffer += lexeme
      else
        if origin.return_end != true && origin.exclude_end != true
          @mode_buffer += lexeme
        end
        process_buffer
        if origin.exclude_end == true
          @mode_buffer = lexeme
        end
      end
      # JS: do { ...; top = top.parent } while (top !== endMode.parent)
      cur : Mode? = origin
      loop do
        m0 = cur.not_nil!
        if (m0s = m0.scope).is_a?(String) && !m0s.empty?
          @emitter.close_node
        end
        if m0.skip != true && m0.sub_language.nil?
          @relevance += (m0.relevance || 0)
        end
        cur = m0.parent
        break if same_mode?(cur, end_mode.parent)
      end
      @top = cur
      if end_mode.starts
        start_new_mode(end_mode.starts.not_nil!, match)
      end
      origin.return_end == true ? 0 : lexeme.bytesize
    end

    private def same_mode?(a : Mode?, b : Mode?) : Bool
      return true if a.nil? && b.nil?
      return false if a.nil? || b.nil?
      a.same?(b)
    end

    private def process_continuations
      list = [] of String
      current : Mode? = @top
      while current && !current.same?(@language)
        if (s = current.scope).is_a?(String) && !s.empty?
          list.unshift(s)
        end
        current = current.parent
      end
      list.each { |s| @emitter.open_node(s) }
    end

    # --- processLexeme ---

    private def process_lexeme(text_before_match : String, match : EnhancedMatch?) : Int32
      lexeme = match.try(&.text)

      @mode_buffer += text_before_match

      if match.nil?
        process_buffer
        return 0
      end

      m = match.not_nil!

      # 0-width begin/end на одной позиции — прокидываем застрявший символ
      if @last_match.try(&.type) == "begin" && m.type == "end" &&
         @last_match.try(&.index) == m.index && lexeme == ""
        if m.index < @code.bytesize
          len = JSRe.char_bytesize_at(@code, m.index)
          @mode_buffer += @code.byte_slice(m.index, len)
          unless @hljs.safe_mode?
            raise Exception.new("0 width match regex (#{@language_name})")
          end
          return len
        end
      end
      @last_match = m

      if m.type == "begin"
        return do_begin_match(m)
      elsif m.type == "illegal" && !@ignore_illegals
        scope_name = top!.scope.is_a?(String) ? top!.scope.to_s : "<unnamed>"
        raise IllegalError.new("Illegal lexeme \"#{lexeme}\" for mode \"#{scope_name}\"", @top)
      elsif m.type == "end"
        processed = do_end_match(m)
        return processed if processed != NO_MATCH
      end

      # illegal по `$` (0-width, не begin/end)
      if m.type == "illegal" && lexeme == ""
        if m.index != @code.bytesize
          @mode_buffer += "\n"
        end
        return 1
      end

      if @iterations > 100000 && @iterations > m.index * 3
        raise Exception.new("potential infinite loop, way more iterations than matches")
      end

      @mode_buffer += m.text
      m.text.bytesize
    end
  end
end
