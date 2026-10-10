# Порт lib/languages/xml.js (highlight.js 11.12.0).

module Highlight::Languages
  module XmlLang
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # XML names can have the following additional letters: https://www.w3.org/TR/xml/#NT-NameChar
      # however, to cater for performance and more Unicode support rely simply on the Unicode letter class
      tag_name_re = regex.concat(/[\p{L}_]/, regex.optional(/[\p{L}0-9_.-]*:/), /[\p{L}0-9_.-]*/)
      xml_ident_re = /[\p{L}0-9._:-]+/
      xml_entities = Mode.new.apply(
        class_name: "symbol",
        begin: /&[a-z]+;|&#[0-9]+;|&#x[a-f0-9]+;/
      )
      xml_meta_keywords = Mode.new.apply(
        begin: /\s/,
        contains: [
          Mode.new.apply(
            class_name: "keyword",
            begin: /#?[a-z_][a-z1-9_-]+/,
            illegal: /\n/
          ),
        ] of Mode
      )
      xml_meta_par_keywords = xml_meta_keywords.inherit(Mode.new.apply(
        begin: /\(/,
        end: /\)/
      ))
      apos_meta_string_mode = MODES::APOS_STRING_MODE.inherit(Mode.new.apply(class_name: "string"))
      quote_meta_string_mode = MODES::QUOTE_STRING_MODE.inherit(Mode.new.apply(class_name: "string"))
      tag_internals = Mode.new.apply(
        ends_with_parent: true,
        illegal: /</,
        relevance: 0,
        contains: [
          Mode.new.apply(
            class_name: "attr",
            begin: xml_ident_re,
            relevance: 0
          ),
          Mode.new.apply(
            begin: /=\s*/,
            relevance: 0,
            contains: [
              Mode.new.apply(
                class_name: "string",
                ends_parent: true,
                variants: [
                  Mode.new.apply(
                    begin: /"/,
                    end: /"/,
                    contains: [xml_entities] of Mode
                  ),
                  Mode.new.apply(
                    begin: /'/,
                    end: /'/,
                    contains: [xml_entities] of Mode
                  ),
                  Mode.new.apply(begin: /[^\s"'=<>`]+/),
                ] of Mode
              ),
            ] of Mode
          ),
        ] of Mode
      )
      Mode.new.apply(
        name: "HTML, XML",
        aliases: [
          "html",
          "xhtml",
          "rss",
          "atom",
          "xjb",
          "xsd",
          "xsl",
          "plist",
          "wsf",
          "svg",
        ],
        case_insensitive: true,
        unicode_regex: true,
        contains: [
          Mode.new.apply(
            class_name: "meta",
            begin: /<![a-z]/,
            end: />/,
            relevance: 10,
            contains: [
              xml_meta_keywords,
              quote_meta_string_mode,
              apos_meta_string_mode,
              xml_meta_par_keywords,
              Mode.new.apply(
                begin: /\[/,
                end: /\]/,
                contains: [
                  Mode.new.apply(
                    class_name: "meta",
                    begin: /<![a-z]/,
                    end: />/,
                    contains: [
                      xml_meta_keywords,
                      xml_meta_par_keywords,
                      quote_meta_string_mode,
                      apos_meta_string_mode,
                    ] of Mode
                  ),
                ] of Mode
              ),
            ] of Mode
          ),
          hljs.comment(
            /<!--/,
            /-->/,
            Mode.new.apply(relevance: 10)
          ),
          Mode.new.apply(
            begin: /<!\[CDATA\[/,
            end: /\]\]>/,
            relevance: 10
          ),
          xml_entities,
          # xml processing instructions
          Mode.new.apply(
            class_name: "meta",
            end: /\?>/,
            variants: [
              Mode.new.apply(
                begin: /<\?xml/,
                relevance: 10,
                contains: [quote_meta_string_mode] of Mode
              ),
              Mode.new.apply(
                begin: /<\?[a-z][a-z0-9]+/,
              ),
            ] of Mode
          ),
          Mode.new.apply(
            class_name: "tag",
            # The lookahead pattern (?=...) ensures that 'begin' only matches
            # '<style' as a single word, followed by a whitespace or an
            # ending bracket.
            begin: /<style(?=\s|>)/,
            end: />/,
            keywords: {"name" => "style"} of String => KeywordsVal,
            contains: [tag_internals] of Mode,
            starts: Mode.new.apply(
              end: /<\/style>/,
              return_end: true,
              sub_language: "css"
            )
          ),
          Mode.new.apply(
            class_name: "tag",
            # See the comment in the <style tag about the lookahead pattern
            begin: /<script(?=\s|>)/,
            end: />/,
            keywords: {"name" => "script"} of String => KeywordsVal,
            contains: [tag_internals] of Mode,
            starts: Mode.new.apply(
              end: /<\/script>/,
              return_end: true,
              sub_language: "javascript"
            )
          ),
          # we need this for now for jSX
          Mode.new.apply(
            class_name: "tag",
            begin: /<>|<\/>/
          ),
          # open tag
          Mode.new.apply(
            class_name: "tag",
            begin: regex.concat(
              /</,
              regex.lookahead(regex.concat(
                tag_name_re,
                # <tag/>
                # <tag>
                # <tag ...
                regex.either([/\/>/, />/, /\s/] of String | Regex)
              ))
            ),
            end: /\/?>/,
            contains: [
              Mode.new.apply(
                class_name: "name",
                begin: tag_name_re,
                relevance: 0,
                starts: tag_internals
              ),
            ] of Mode
          ),
          # close tag
          Mode.new.apply(
            class_name: "tag",
            begin: regex.concat(
              /<\//,
              regex.lookahead(regex.concat(
                tag_name_re, />/
              ))
            ),
            contains: [
              Mode.new.apply(
                class_name: "name",
                begin: tag_name_re,
                relevance: 0
              ),
              Mode.new.apply(
                begin: />/,
                relevance: 0,
                ends_parent: true
              ),
            ] of Mode
          ),
        ] of Mode
      )
    end
  end

  Languages.register("xml", ->(hljs : HLJS) { XmlLang.defined(hljs) })
end
