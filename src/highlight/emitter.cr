# Порт TokenTree / TokenTreeEmitter / HTMLRenderer из core.js.

module Highlight
  SPAN_CLOSE = "</span>"

  def self.escape_html(value : String) : String
    value.gsub('&', "&amp;")
      .gsub('<', "&lt;")
      .gsub('>', "&gt;")
      .gsub('"', "&quot;")
      .gsub('\'', "&#x27;")
  end

  class TreeNode
    property scope : String?
    property children = [] of TreeChild

    def initialize(@scope = nil)
    end
  end

  alias TreeChild = TreeNode | String

  class HTMLRenderer
    @buffer = String::Builder.new
    @class_prefix : String

    def initialize(root : TreeNode, class_prefix : String)
      @class_prefix = class_prefix
      walk(root)
    end

    def value : String
      @buffer.to_s
    end

    private def walk(node : TreeChild)
      case node
      when String
        @buffer << Highlight.escape_html(node)
      when TreeNode
        open_node(node)
        node.children.each { |child| walk(child) }
        close_node(node)
      end
    end

    private def emits_wrapping_tags?(node : TreeNode) : Bool
      !!node.scope
    end

    private def open_node(node : TreeNode)
      return unless emits_wrapping_tags?(node)
      @buffer << "<span class=\"" << scope_to_css_class(node.scope.not_nil!) << "\">"
    end

    private def close_node(node : TreeNode)
      return unless emits_wrapping_tags?(node)
      @buffer << SPAN_CLOSE
    end

    # scopeToCSSClass: субязык "language:x" / tiered "comment.line" / простой
    def scope_to_css_class(name : String) : String
      if name.starts_with?("language:")
        return name.sub("language:", "language-")
      end
      if name.includes?(".")
        pieces = name.split(".")
        first = pieces.shift
        parts = ["#{@class_prefix}#{first}"]
        pieces.each_with_index { |x, i| parts << "#{x}#{"_" * (i + 1)}" }
        return parts.join(" ")
      end
      "#{@class_prefix}#{name}"
    end
  end

  class TokenTree
    property root : TreeNode = TreeNode.new
    @stack = [] of TreeNode

    def initialize
      @stack = [@root]
    end

    def top : TreeNode
      @stack.last
    end

    def add(node : TreeChild)
      top.children << node
    end

    def open_node(scope : String?)
      node = TreeNode.new(scope)
      add(node)
      @stack.push(node)
    end

    def close_node
      if @stack.size > 1
        return @stack.pop
      end
      nil
    end

    def close_all_nodes
      while close_node
      end
    end
  end

  class TokenTreeEmitter < TokenTree
    def initialize
      super()
    end

    def add_text(text : String)
      return if text == ""
      add(text)
    end

    def start_scope(scope : String?)
      open_node(scope)
    end

    def end_scope
      close_node
    end

    def add_sublanguage(emitter : TokenTreeEmitter, name : String?)
      node = emitter.root
      node.scope = "language:#{name}" if name
      add(node)
    end

    def to_html(class_prefix : String) : String
      HTMLRenderer.new(root, class_prefix).value
    end

    def finalize
      close_all_nodes
      true
    end
  end
end
