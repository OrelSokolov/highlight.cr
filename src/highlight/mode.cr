# Модель режима (Mode) — аналог JS-объектов `Mode`/`CompiledMode`/`Language`
# из core.js. Все поля нилабельные по образцу «ключ присутствует ⇔ поле
# выставлено»: это важно для `inherit`-семантики и компилятора режимов.

module Highlight
  alias Pattern = String | Regex | Array(String | Regex)

  # keywords: "a b c" | ["a","b"] | {"keyword": [...], "$pattern": "..."}
  alias KeywordsVal = String | Array(String) | Hash(String, KeywordsVal)

  # beginScope/endScope: "scope" | {1 => "x", 2 => "y"} (до компиляции);
  # после компиляции — CompiledScope
  class CompiledScope
    property wrap : String? = nil
    property positions = {} of Int32 => String
    property emit = {} of Int32 => Bool
    property? multi : Bool = false

    def [](i : Int32) : String?
      positions[i]?
    end

    def emit?(i : Int32) : Bool
      emit[i]? || false
    end
  end

  alias ScopeVal = String | Hash(String, String) | CompiledScope

  alias ModeCallback = Proc(EnhancedMatch, Response, Nil)
  alias CompilerExt = Proc(Mode, Mode?, Nil)
  alias MatchGroups = Hash(String, Tuple(String, Int32))

  # Совпадение «как в JS» после splice из MultiRegex: `[0]` — текст
  # совпавшей альтернативы, `[1..]` — её группы; index абсолютный.
  class EnhancedMatch
    property index : Int32 = 0
    property input : String = ""
    property text : String = ""
    property groups : Array(String?) = [] of String?
    property rule : Mode? = nil
    property type : String? = nil
    property position : Int32 = 0

    def [](i : Int32) : String?
      i == 0 ? text : groups[i - 1]?
    end
  end

  # CallbackResponse: доступ к mode.data + ignoreMatch
  class Response
    getter data : Hash(String, String)
    property? is_match_ignored : Bool = false

    def initialize(mode : Mode)
      mode.data ||= {} of String => String
      @data = mode.data.not_nil!
    end

    def ignore_match
      @is_match_ignored = true
      nil
    end
  end

  class Mode
    # маркер 'self' в contains (разрешается в compileMode)
    class_property self_marker : Mode { Mode.new }

    # --- Language-метаданные ---
    property name : String?
    property aliases : Array(String)?
    property superset_of : String?
    property disable_autodetect : Bool? = nil
    property exports : Hash(String, Mode | KeywordsVal | Array(Mode))? = nil
    property raw_definition : Proc(HLJS, Mode)? = nil

    # --- scope-ы ---
    property scope : ScopeVal? = nil
    property class_name : String? = nil # легаси, переводится в scope
    property begin_scope : ScopeVal? = nil
    property end_scope : ScopeVal? = nil

    # --- паттерны ---
    property begin : Pattern? = nil
    property end : Pattern? = nil
    property match : Pattern? = nil
    property illegal : Pattern? = nil
    property begin_keywords : String? = nil
    property before_match : Pattern? = nil
    property keywords : KeywordsVal? = nil

    # --- структура ---
    property contains : Array(Mode)? = nil
    property starts : Mode? = nil
    property variants : Array(Mode)? = nil
    property cached_variants : Array(Mode)? = nil
    property sub_language : (String | Array(String))? = nil # subLanguage

    # --- language-уровень ---
    property case_insensitive : Bool? = nil
    property unicode_regex : Bool? = nil
    property class_name_aliases : Hash(String, String)? = nil
    property compiler_extensions : Array(CompilerExt)? = nil

    # --- флаги ---
    property skip : Bool? = nil
    property label : String? = nil
    property exclude_begin : Bool? = nil
    property exclude_end : Bool? = nil
    property return_begin : Bool? = nil
    property return_end : Bool? = nil
    property ends_parent : Bool? = nil
    property ends_with_parent : Bool? = nil
    property relevance : Int32 | Float64? = nil

    # --- колбэки ---
    property on_begin : ModeCallback? = nil # "on:begin"
    property on_end : ModeCallback? = nil   # "on:end"
    property before_begin : ModeCallback? = nil # __beforeBegin

    # --- runtime/компиляция ---
    property data : Hash(String, String)? = nil
    property parent : Mode? = nil
    property? is_compiled : Bool = false
    property keyword_pattern_re : JSRe? = nil
    property begin_re : JSRe? = nil
    property end_re : JSRe? = nil
    property illegal_re : JSRe? = nil
    property terminator_end : String? = nil
    property keywords_compiled : MatchGroups? = nil
    property matcher : ResumableMultiRegex? = nil

    # аналог Object.freeze: expandOrCloneMode делает копию замороженного
    property? frozen_content : Bool = false

    def initialize
    end

    def self.frozen(**fields)
      m = Mode.new
      m.apply(**fields)
      m.frozen_content = true
      m
    end

    # удобно задавать поля через именованные аргументы (аналог литерала объекта)
    def apply(**fields)
      {% for f in @type.instance_vars %}
        {% if f.name != "frozen_content" && f.name != "is_compiled" %}
          if fields[{{ ":#{f.name}".id }}]?
            self.{{f.name.id}} = fields[{{ ":#{f.name}".id }}]?
          end
        {% end %}
      {% end %}
      self
    end

    # аналог Object.create(mode, {parent}) — клон с parent-ом
    def derive(parent : Mode?) : Mode
      m = self.dup_shallow
      m.parent = parent
      m
    end

    def dup_shallow : Mode
      m = Mode.new
      m.copy_from(self)
      m
    end

    # JS inherit: копия base, поверх — поля override (только присутствующие).
    # clear_* — явные `null`-перезаписи из оригинала (copy_from nil не чистит).
    def inherit(override : Mode? = nil, *, clear_variants : Bool = false, clear_starts : Bool = false,
                clear_scope : Bool = false, clear_illegal : Bool = false, clear_contains : Bool = false) : Mode
      m = self.dup_shallow
      m.variants = nil if clear_variants
      m.starts = nil if clear_starts
      m.scope = nil if clear_scope
      m.illegal = nil if clear_illegal
      m.contains = nil if clear_contains
      m.copy_from(override) if override
      m
    end

    protected def copy_from(other : Mode?)
      return if other.nil?
      {% for f in @type.instance_vars %}
        {% if f.name != "frozen_content" && f.name != "is_compiled" %}
          if v = other.@{{f.name.id}}
            self.{{f.name.id}} = v
          end
        {% end %}
      {% end %}
    end
  end
end
