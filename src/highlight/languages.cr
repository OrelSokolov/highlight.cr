# Реестр определений языков + регистрация common-набора
# (порядок как в lib/common.js — важен для автодетекта при ничьих).

module Highlight
  module Languages
    LANGUAGE_FNS = {} of String => Proc(HLJS, Mode)

    def self.register(name : String, fn : Proc(HLJS, Mode))
      LANGUAGE_FNS[name] = fn
    end

    def self.language_fn(name : String) : Proc(HLJS, Mode)?
      LANGUAGE_FNS[name]?
    end

    COMMON_LANGUAGES = [
      "xml", "bash", "c", "cpp", "csharp", "css", "markdown", "diff",
      "ruby", "go", "graphql", "ini", "java", "javascript", "json",
      "kotlin", "less", "lua", "makefile", "perl", "objectivec", "php",
      "php-template", "plaintext", "python", "python-repl", "r", "rust",
      "scss", "shell", "sql", "swift", "yaml", "typescript", "vbnet", "wasm",
    ] of String

    def self.register_common(hljs : HLJS)
      COMMON_LANGUAGES.each do |name|
        fn = language_fn(name)
        STDERR.puts "WARN: highlight.cr: no language definition: #{name}" unless fn
        next if fn.nil?
        hljs.register_language(name, fn)
      end
    end
  end

  # Глобальный экземпляр (аналог module.exports = hljs)
  class HLJS
    @@default : HLJS? = nil

    def self.default : HLJS
      if (d = @@default)
        d
      else
        hljs = HLJS.new
        Languages.register_common(hljs)
        @@default = hljs
        hljs
      end
    end
  end

  def self.default : HLJS
    HLJS.default
  end

  def self.highlight(code : String, language : String?, ignore_illegals : Bool = true)
    default.highlight(code, language, ignore_illegals)
  end

  def self.highlight_auto(code : String, subset : Array(String)? = nil)
    default.highlight_auto(code, subset)
  end

  # Плоский список токенов {scope, text} для GUI-потребителей: DFS по
  # дереву эмиттера (HighlightResult#emitter.root); для текста под
  # вложенными узлами выигрывает ближайший ненулевой scope.
  # language = nil → автодетект (highlight_auto); незарегистрированный
  # язык → nil — вызывающий деградирует сам.
  def self.tokens(code : String, language : String?) : Array(Tuple(String?, String))?
    hljs = default
    result =
      if language
        return nil if hljs.get_language(language).nil?
        hljs.highlight(code, language)
      else
        hljs.highlight_auto(code)
      end
    tokens = [] of Tuple(String?, String)
    collect_tokens(result.emitter.root, nil, tokens)
    tokens
  end

  private def self.collect_tokens(node : TreeNode, scope : String?,
                                  acc : Array(Tuple(String?, String))) : Nil
    node.children.each do |child|
      if child.is_a?(String)
        acc << {scope, child}
      else
        collect_tokens(child, child.scope || scope, acc)
      end
    end
  end
end

require "./languages/*"
