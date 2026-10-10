# JS→PCRE совместимость: highlight.js использует JS-регексы, а Crystal —
# PCRE в Unicode/UCP-режиме. Расхождения, которые обязан закрыть этот
# модуль (остальное в PLAN.md):
#
#   \w \d — в JS всегда ASCII, в Crystal/PCRE+UCP — юникод  → перезапись
#   \b \B — граница слова: JS по ASCII-слову, PCRE+UCP по юникод-слову
#   \uXXXX / \u{...} — JS-escape, PCRE знает \x{...}
#   \s \S — оставляем как есть: PCRE+UCP ≈ JS-набор (кроме U+FEFF)
#
# Перезаписи вводят только не-захватывающие группы `(?:`, `(?=`, `(?<=`,
# `(?<!`, `(?!` — счёт групп в паттерне не меняется, что важно для
# `_rewrite_backreferences` и `count_match_groups`.

module Highlight
  module JSRegex
    # NBSP и прочие JS-пробелы не входят в ASCII \s, но PCRE+UCP покрывает
    # их сам (кроме U+FEFF) — \s/\S не трогаем.

    WORD      = "A-Za-z0-9_"
    WORD_RE   = "[#{WORD}]"
    NWORD_RE  = "[^#{WORD}]"
    DIGIT_RE  = "[0-9]"
    NDIGIT_RE = "[^0-9]"
    # \b: позиция между не-словом и словом либо словом и не-словом (ASCII)
    B_RE  = "(?:(?<![#{WORD}])(?=[#{WORD}])|(?<=[#{WORD}])(?![#{WORD}]))"
    # \B: обе стороны одного рода
    NB_RE = "(?:(?<=[#{WORD}])(?=[#{WORD}])|(?<![#{WORD}])(?![#{WORD}]))"

    # Переводит source JS-регекса в PCRE-совместимый source.
    def self.translate(src : String) : String
      out = String::Builder.new(src.bytesize)
      i = 0
      bytes = src.to_slice
      in_class = false

      while i < bytes.size
        c = bytes[i]
        if c == '\\'.ord
          nxt = bytes[i + 1]?
          if nxt.nil?
            out << "\\"
            break
          end
          case nxt
          when 'w'.ord
            out << (in_class ? WORD : WORD_RE)
            i += 2
          when 'd'.ord
            out << (in_class ? "0-9" : DIGIT_RE)
            i += 2
          when 'b'.ord
            # внутри класса \b — это backspace (как и в JS)
            out << (in_class ? "\\b" : B_RE)
            i += 2
          when 'W'.ord
            raise_translate(src, "\\W") if in_class
            out << NWORD_RE
            i += 2
          when 'D'.ord
            raise_translate(src, "\\D") if in_class
            out << NDIGIT_RE
            i += 2
          when 'B'.ord
            raise_translate(src, "\\B") if in_class
            out << NB_RE
            i += 2
          when 's'.ord, 'S'.ord
            # см. комментарий модуля
            out << "\\"
            out.write_byte nxt
            i += 2
          when 'u'.ord
            # \uXXXX или \u{...} → \x{...}
            if bytes[i + 2]? == '{'.ord
              j = i + 3
              while j < bytes.size && bytes[j] != '}'.ord
                j += 1
              end
              hex = src[(i + 3)...j]
              out << "\\x{" << hex << "}"
              i = j + 1
            else
              hex = src[(i + 2)...(i + 6)]? || raise_translate(src, "\\u")
              out << "\\x{" << hex << "}"
              i += 6
            end
          else
            out << "\\"
            out.write_byte nxt
            i += 2
          end
        elsif c == '['.ord && !in_class
          in_class = true
          out << '['
          i += 1
          # '^' в начале класса и литеральный ']' сразу после '[' / '[^'
          if bytes[i]? == '^'.ord
            out << '^'
            i += 1
          end
          if bytes[i]? == ']'.ord
            out << "\\]"
            i += 1
          end
        elsif c == ']'.ord && in_class
          in_class = false
          out << ']'
          i += 1
        elsif c == '.'.ord && !in_class
          # JS-флаг 'm' не даёт DOTALL: точка не пересекает границы строк.
          # Crystal MULTILINE включает DOTALL, поэтому разворачиваем вручную.
          out << "[^\\n\\r\\x{2028}\\x{2029}]"
          i += 1
        else
          out.write_byte c
          i += 1
        end
      end

      out.to_s
    end

    private def self.raise_translate(src, what)
      raise ArgumentError.new("JSRegex: #{what} внутри символьного класса не поддерживается: #{src}")
    end

    # Число захватывающих групп в паттерне. Тот же трюк, что в оригинале:
    # `new RegExp(src + '|').exec('')` — добавление пустой альтернативы
    # позволяет сопоставить пустую строку; size включает группу 0.
    def self.count_match_groups(src : String) : Int32
      md = Regex.new(translate(src) + "|").match("")
      md ? md.size - 1 : 0
    end

    # См. core.js BACKREF_RE + _rewriteBackreferences: склейка альтернатив
    # с перенумерацией бэкреференсов, каждая заворачивается в группу.
    BACKREF_RE = /\[(?:[^\\\]]|\\.)*\]|\(\?<(?![=!])[^>]+>|\(\?'[^']+'|\(\??|\\([1-9][0-9]*)|\\./

    def self.rewrite_backreferences(regexps : Array(String), join_with : String) : String
      num_captures = 0

      regexps.map do |regex|
        num_captures += 1
        offset = num_captures
        re = regex
        out = ""

        while re.size > 0
          m = BACKREF_RE.match(re)
          if m.nil?
            out += re
            break
          end
          b = m.byte_begin(0).not_nil!
          out += re.byte_slice(0, b)
          re = re.byte_slice(b + m[0].bytesize)
          if m[0][0]? == '\\' && m[1]?
            # поправить номер бэкреференса
            out += '\\' + (m[1].not_nil!.to_i + offset).to_s
          else
            out += m[0]
            if m[0] == "(" || /^\(\?[<']/.matches?(m[0])
              num_captures += 1
            end
          end
        end
        out
      end.map { |re| "(#{re})" }.join(join_with)
    end
  end

  # Обёртка над Regex с JS-семантикой global-exec: поиск с last_index,
  # после пустого совпадения last_index = index + 1, при неудаче — сброс в 0.
  class JSRe
    getter regex : Regex
    property last_index : Int32 = 0

    def initialize(source : String, ignore_case : Bool = false)
      opts = Regex::Options::MULTILINE
      opts |= Regex::Options::IGNORE_CASE if ignore_case
      translated = JSRegex.translate(source)
      if ENV["HLJS_TRACE"]?
        md = begin
          Regex.new(translated, opts)
        rescue ex
          STDERR.puts "JSRe FAIL: #{translated.inspect}"
          raise ex
        end
        @regex = md
      else
        @regex = Regex.new(translated, opts)
      end
    end

    def exec(s : String) : Regex::MatchData?
      md = @regex.match_at_byte_index(s, @last_index)
      if md
        b = md.byte_begin(0).not_nil!
        e = md.byte_end(0).not_nil!
        # JS: после пустого совпадения lastIndex = index + 1 (UTF-16-юнит);
        # в байтах — до границы следующего символа
        @last_index = e == b ? JSRe.char_advance(s, b) : e
      else
        @last_index = 0
      end
      md
    end

    # Смещение на один символ вперёд от байтового индекса (аналог +1 UTF-16-юнита)
    def self.char_advance(s : String, byte_index : Int32) : Int32
      return byte_index + 1 if byte_index >= s.bytesize
      byte_index + char_bytesize_at(s, byte_index)
    end

    # Размер UTF-8 символа по байтовому смещению (byte_at — байтовый индекс)
    def self.char_bytesize_at(s : String, byte_index : Int32) : Int32
      case s.byte_at(byte_index)
      when .< 0x80 then 1
      when .< 0xC0 then 1 # continuation-байт: некорректная позиция, минимум 1
      when .< 0xE0 then 2
      when .< 0xF0 then 3
      else              4
      end
    end

    # exec + проверка, что совпадение начинается ровно с pos
    # (JS: re.exec(lexeme) c match.index === 0 — «начинается с»)
    def self.match_starts_with(re : Regex, lexeme : String) : Bool
      md = re.match(lexeme)
      !md.nil? && md.begin(0) == 0
    end
  end
end
