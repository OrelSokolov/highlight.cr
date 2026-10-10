# Порт lib/languages/yaml.js (highlight.js 11.12.0).

module Highlight::Languages
  module YamlLang
    def self.defined(hljs : HLJS) : Mode
      literals = "true false yes no null"

      # YAML spec allows non-reserved URI characters in tags.
      uri_characters = "[\\w#;/?:@&=+$,.~*'()\\[\\]]+"

      # Define keys as starting with a word character
      # ...containing word chars, spaces, colons, forward-slashes, hyphens and periods
      # ...and ending with a colon followed immediately by a space, tab or newline.
      # The YAML spec allows for much more than this, but this covers most use-cases.
      key = Mode.new.apply(
        class_name: "attr",
        variants: [
          # added brackets support and special char support
          Mode.new.apply(begin: %r([\w*@][\w*@ :()\./-]*:(?=[ \t]|$))),
          # double quoted keys - with brackets and special char support
          Mode.new.apply(begin: %r("[\w*@][\w*@ :()\./-]*":(?=[ \t]|$))),
          # single quoted keys - with brackets and special char support
          Mode.new.apply(begin: %r('[\w*@][\w*@ :()\./-]*':(?=[ \t]|$))),
        ] of Mode
      )

      template_variables = Mode.new.apply(
        class_name: "template-variable",
        variants: [
          # jinja templates Ansible
          Mode.new.apply(begin: /\{\{/, end: /\}\}/),
          # Ruby i18n
          Mode.new.apply(begin: /%\{/, end: /\}/),
        ] of Mode
      )

      single_quote_string = Mode.new.apply(
        class_name: "string",
        relevance: 0,
        begin: /'/,
        end: /'/,
        contains: [
          Mode.new.apply(
            match: /''/,
            scope: "char.escape",
            relevance: 0
          ),
        ] of Mode
      )

      string_mode = Mode.new.apply(
        class_name: "string",
        relevance: 0,
        variants: [
          Mode.new.apply(begin: /"/, end: /"/),
          Mode.new.apply(begin: /\S+/),
        ] of Mode,
        contains: [
          MODES::BACKSLASH_ESCAPE,
          template_variables,
        ] of Mode
      )

      # Strings inside of value containers (objects) can't contain braces,
      # brackets, or commas
      container_string = string_mode.inherit(Mode.new.apply(variants: [
        Mode.new.apply(
          begin: /'/,
          end: /'/,
          contains: [
            Mode.new.apply(
              begin: /''/,
              relevance: 0
            ),
          ] of Mode
        ),
        Mode.new.apply(
          begin: /"/,
          end: /"/
        ),
        Mode.new.apply(begin: %r([^\s,{}[\]]+)),
      ] of Mode))

      date_re = "[0-9]{4}(-[0-9][0-9]){0,2}"
      time_re = "([Tt \\t][0-9][0-9]?(:[0-9][0-9]){2})?"
      fraction_re = "(\\.[0-9]*)?"
      zone_re = "([ \\t])*(Z|[-+][0-9][0-9]?(:[0-9][0-9])?)?"
      timestamp = Mode.new.apply(
        class_name: "number",
        begin: "\\b" + date_re + time_re + fraction_re + zone_re + "\\b"
      )

      value_container = Mode.new.apply(
        end: ",",
        ends_with_parent: true,
        exclude_end: true,
        keywords: literals,
        relevance: 0
      )
      object = Mode.new.apply(
        begin: /\{/,
        end: /\}/,
        contains: [value_container] of Mode,
        illegal: "\\n",
        relevance: 0
      )
      array = Mode.new.apply(
        begin: "\\[",
        end: "\\]",
        contains: [value_container] of Mode,
        illegal: "\\n",
        relevance: 0
      )

      all_modes = [
        key,
        Mode.new.apply(
          class_name: "meta",
          begin: "^---\\s*$",
          relevance: 10
        ),
        # multi line string
        # Blocks start with a | or > followed by a newline
        #
        # Indentation of subsequent lines must be the same to
        # be considered part of the block
        Mode.new.apply(
          class_name: "string",
          begin: "[\\|>]([1-9]?[+-])?[ ]*\\n( +)[^ ][^\\n]*\\n(\\2[^\\n]+\\n?)*"
        ),
        # Ruby/Rails erb
        Mode.new.apply(
          begin: "<%[%=-]?",
          end: "[%-]?%>",
          sub_language: "ruby",
          exclude_begin: true,
          exclude_end: true,
          relevance: 0
        ),
        # named tags
        Mode.new.apply(
          class_name: "type",
          begin: "!\\w+!" + uri_characters
        ),
        # https://yaml.org/spec/1.2/spec.html#id2784064
        # verbatim tags
        Mode.new.apply(
          class_name: "type",
          begin: "!<" + uri_characters + ">"
        ),
        # primary tags
        Mode.new.apply(
          class_name: "type",
          begin: "!" + uri_characters
        ),
        # secondary tags
        Mode.new.apply(
          class_name: "type",
          begin: "!!" + uri_characters
        ),
        # fragment id &ref
        Mode.new.apply(
          class_name: "meta",
          begin: "&" + UNDERSCORE_IDENT_RE + "$"
        ),
        # fragment reference *ref
        Mode.new.apply(
          class_name: "meta",
          begin: "\\*" + UNDERSCORE_IDENT_RE + "$"
        ),
        # array listing
        Mode.new.apply(
          class_name: "bullet",
          # TODO: remove |$ hack when we have proper look-ahead support
          begin: "-(?=[ ]|$)",
          relevance: 0
        ),
        MODES::HASH_COMMENT_MODE,
        Mode.new.apply(
          begin_keywords: literals,
          keywords: {"literal" => literals} of String => KeywordsVal
        ),
        timestamp,
        # numbers are any valid C-style number that
        # sit isolated from other words
        Mode.new.apply(
          class_name: "number",
          begin: C_NUMBER_RE + "\\b",
          relevance: 0
        ),
        object,
        array,
        single_quote_string,
        string_mode,
      ] of Mode

      value_modes = all_modes.dup
      value_modes.pop
      value_modes << container_string
      value_container.contains = value_modes

      Mode.new.apply(
        name: "YAML",
        case_insensitive: true,
        aliases: ["yml"],
        contains: all_modes
      )
    end
  end

  Languages.register("yaml", ->(hljs : HLJS) { YamlLang.defined(hljs) })
end
