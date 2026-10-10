# Порт lib/languages/ruby.js (highlight.js 11.12.0).

module Highlight::Languages
  module RubyLang
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      r_u_b_y__m_e_t_h_o_d__r_e = "([a-zA-Z_]\\w*[!?=]?|[-+~]@|<<|>>|=~|===?|<=>|[<>]=?|\\*\\*|[-/+%^&*~`|]|\\[\\]=?)"
      c_l_a_s_s__n_a_m_e__r_e = regex.either([
        /\b([A-Z]+[a-z0-9]+)+/,
        /\b([A-Z]+[a-z0-9]+)+[A-Z]+/,
      ])
      c_l_a_s_s__n_a_m_e__w_i_t_h__n_a_m_e_s_p_a_c_e__r_e = regex.concat(c_l_a_s_s__n_a_m_e__r_e, /(::\w+)*/)
      p_s_e_u_d_o__k_w_s = ["include", "extend", "prepend", "public", "private", "protected", "raise", "throw"]
      r_u_b_y__k_e_y_w_o_r_d_s = {} of String => KeywordsVal
      r_u_b_y__k_e_y_w_o_r_d_s["variable.constant"] = ["__FILE__", "__LINE__", "__ENCODING__"]
      r_u_b_y__k_e_y_w_o_r_d_s["variable.language"] = ["self", "super"]
      r_u_b_y__k_e_y_w_o_r_d_s["keyword"] = [
        "alias", "and", "begin", "BEGIN", "break", "case", "class", "defined",
        "do", "else", "elsif", "end", "END", "ensure", "for", "if", "in",
        "module", "next", "not", "or", "redo", "require", "rescue", "retry",
        "return", "then", "undef", "unless", "until", "when", "while", "yield",
      ] + p_s_e_u_d_o__k_w_s
      r_u_b_y__k_e_y_w_o_r_d_s["built_in"] = [
        "proc", "lambda", "attr_accessor", "attr_reader", "attr_writer",
        "define_method", "private_constant", "module_function",
      ]
      r_u_b_y__k_e_y_w_o_r_d_s["literal"] = ["true", "false", "nil"]

      y_a_r_d_o_c_t_a_g = Mode.new.apply(class_name: "doctag", begin: "@[A-Za-z]+")
      i_r_b__o_b_j_e_c_t = Mode.new.apply(begin: "#<", end: ">")
      c_o_m_m_e_n_t__m_o_d_e_s = [
        hljs.comment("#", "$", Mode.new.apply(contains: [y_a_r_d_o_c_t_a_g])),
        hljs.comment("^=begin", "^=end", Mode.new.apply(contains: [y_a_r_d_o_c_t_a_g], relevance: 10)),
        hljs.comment("^__END__", MATCH_NOTHING_RE),
      ] of Mode
      s_u_b_s_t = Mode.new.apply(
        class_name: "subst",
        begin: /#\{/,
        end: /\}/,
        keywords: r_u_b_y__k_e_y_w_o_r_d_s
      )
      s_t_r_i_n_g = Mode.new.apply(
        class_name: "string",
        contains: [
          MODES::BACKSLASH_ESCAPE,
          s_u_b_s_t,
        ] of Mode,
        variants: [
          Mode.new.apply(begin: /'/, end: /'/),
          Mode.new.apply(begin: /"/, end: /"/),
          Mode.new.apply(begin: /`/, end: /`/),
          Mode.new.apply(begin: /%[qQwWx]?\(/, end: /\)/),
          Mode.new.apply(begin: /%[qQwWx]?\[/, end: /\]/),
          Mode.new.apply(begin: /%[qQwWx]?\{/, end: /\}/),
          Mode.new.apply(begin: /%[qQwWx]?</, end: />/),
          Mode.new.apply(begin: /%[qQwWx]?\//, end: /\//),
          Mode.new.apply(begin: /%[qQwWx]?%/, end: /%/),
          Mode.new.apply(begin: /%[qQwWx]?-/, end: /-/),
          Mode.new.apply(begin: /%[qQwWx]?\|/, end: /\|/),
          # \B в начале подавляет распознавание ?-последовательностей,
          # где ? — последний символ предшествующего идентификатора (`func?4`)
          Mode.new.apply(begin: /\B\?(\\\d{1,3})/),
          Mode.new.apply(begin: /\B\?(\\x[A-Fa-f0-9]{1,2})/),
          Mode.new.apply(begin: /\B\?(\\u\{?[A-Fa-f0-9]{1,6}\}?)/),
          Mode.new.apply(begin: /\B\?(\\M-\\C-|\\M-\\c|\\c\\M-|\\M-|\\C-\\M-)[\x20-\x7e]/),
          Mode.new.apply(begin: /\B\?\\(c|C-)[\x20-\x7e]/),
          Mode.new.apply(begin: /\B\?\\?\S/),
          # heredoc-и
          Mode.new.apply(
            begin: regex.concat(
              /<<[-~]?'?/,
              regex.lookahead(/(\w+)(?=\W)[^\n]*\n(?:[^\n]*\n)*?\s*\1\b/)
            ),
            contains: [
              hljs.end_same_as_begin(Mode.new.apply(
                begin: /(\w+)/,
                end: /(\w+)/,
                contains: [
                  MODES::BACKSLASH_ESCAPE,
                  s_u_b_s_t,
                ] of Mode
              )),
            ] of Mode
          ),
        ] of Mode
      )

      decimal = "[1-9](_?[0-9])*|0"
      digits = "[0-9](_?[0-9])*"
      n_u_m_b_e_r = Mode.new.apply(
        class_name: "number",
        relevance: 0,
        variants: [
          Mode.new.apply(begin: "\\b(#{decimal})(\\.(#{digits}))?([eE][+-]?(#{digits})|r)?i?\\b"),
          Mode.new.apply(begin: "\\b0[dD][0-9](_?[0-9])*r?i?\\b"),
          Mode.new.apply(begin: "\\b0[bB][0-1](_?[0-1])*r?i?\\b"),
          Mode.new.apply(begin: "\\b0[oO][0-7](_?[0-7])*r?i?\\b"),
          Mode.new.apply(begin: "\\b0[xX][0-9a-fA-F](_?[0-9a-fA-F])*r?i?\\b"),
          Mode.new.apply(begin: "\\b0(_?[0-7])+r?i?\\b"),
        ] of Mode
      )

      p_a_r_a_m_s = Mode.new.apply(
        variants: [
          Mode.new.apply(match: /\(\)/),
          Mode.new.apply(
            class_name: "params",
            begin: /\(/,
            end: /(?=\))/,
            exclude_begin: true,
            ends_parent: true,
            keywords: r_u_b_y__k_e_y_w_o_r_d_s
          ),
        ] of Mode
      )

      i_n_c_l_u_d_e__e_x_t_e_n_d = Mode.new.apply(
        match: [/(include|extend)\s+/, c_l_a_s_s__n_a_m_e__w_i_t_h__n_a_m_e_s_p_a_c_e__r_e],
        scope: {"2" => "title.class"},
        keywords: r_u_b_y__k_e_y_w_o_r_d_s
      )

      c_l_a_s_s__d_e_f_i_n_i_t_i_o_n = Mode.new.apply(
        variants: [
          Mode.new.apply(
            match: [
              /class\s+/,
              c_l_a_s_s__n_a_m_e__w_i_t_h__n_a_m_e_s_p_a_c_e__r_e,
              /\s+<\s+/,
              c_l_a_s_s__n_a_m_e__w_i_t_h__n_a_m_e_s_p_a_c_e__r_e,
            ],
          ),
          Mode.new.apply(
            match: [/\b(class|module)\s+/, c_l_a_s_s__n_a_m_e__w_i_t_h__n_a_m_e_s_p_a_c_e__r_e],
          ),
        ] of Mode,
        scope: {"2" => "title.class", "4" => "title.class.inherited"},
        keywords: r_u_b_y__k_e_y_w_o_r_d_s
      )

      u_p_p_e_r__c_a_s_e__c_o_n_s_t_a_n_t = Mode.new.apply(
        relevance: 0,
        match: /\b[A-Z][A-Z_0-9]+\b/,
        class_name: "variable.constant"
      )

      m_e_t_h_o_d__d_e_f_i_n_i_t_i_o_n = Mode.new.apply(
        match: [/def/, /\s+/, r_u_b_y__m_e_t_h_o_d__r_e],
        scope: {"1" => "keyword", "3" => "title.function"},
        contains: [p_a_r_a_m_s] of Mode
      )

      o_b_j_e_c_t__c_r_e_a_t_i_o_n = Mode.new.apply(
        relevance: 0,
        match: [c_l_a_s_s__n_a_m_e__w_i_t_h__n_a_m_e_s_p_a_c_e__r_e, /\.new[. (]/],
        scope: {"1" => "title.class"}
      )

      c_l_a_s_s__r_e_f_e_r_e_n_c_e = Mode.new.apply(
        relevance: 0,
        match: c_l_a_s_s__n_a_m_e__r_e,
        scope: "title.class"
      )

      r_u_b_y__d_e_f_a_u_l_t__c_o_n_t_a_i_n_s = [
        s_t_r_i_n_g,
        c_l_a_s_s__d_e_f_i_n_i_t_i_o_n,
        i_n_c_l_u_d_e__e_x_t_e_n_d,
        o_b_j_e_c_t__c_r_e_a_t_i_o_n,
        u_p_p_e_r__c_a_s_e__c_o_n_s_t_a_n_t,
        c_l_a_s_s__r_e_f_e_r_e_n_c_e,
        m_e_t_h_o_d__d_e_f_i_n_i_t_i_o_n,
        Mode.new.apply(begin: "::"),
        Mode.new.apply(
          class_name: "symbol",
          begin: UNDERSCORE_IDENT_RE + "(!|\\?)?:",
          relevance: 0
        ),
        Mode.new.apply(
          class_name: "symbol",
          begin: ":(?!\\s)",
          contains: [
            s_t_r_i_n_g,
            Mode.new.apply(begin: r_u_b_y__m_e_t_h_o_d__r_e),
          ] of Mode,
          relevance: 0
        ),
        n_u_m_b_e_r,
        Mode.new.apply(
          class_name: "variable",
          begin: "(\\$\\W)|((\\$|@@?)(\\w+))(?=[^@$?])(?![A-Za-z])(?![@$?'])"
        ),
        Mode.new.apply(
          class_name: "params",
          begin: /\|(?!=)/,
          end: /\|/,
          exclude_begin: true,
          exclude_end: true,
          relevance: 0,
          keywords: r_u_b_y__k_e_y_w_o_r_d_s
        ),
        Mode.new.apply(
          begin: "(" + RE_STARTERS_RE + "|unless)\\s*",
          keywords: "unless",
          contains: [
            Mode.new.apply(
              class_name: "regexp",
              contains: [
                MODES::BACKSLASH_ESCAPE,
                s_u_b_s_t,
              ] of Mode,
              illegal: /\n/,
              variants: [
                Mode.new.apply(begin: "/", end: "/[a-z]*"),
                Mode.new.apply(begin: /%r\{/, end: /\}[a-z]*/),
                Mode.new.apply(begin: "%r\\(", end: "\\)[a-z]*"),
                Mode.new.apply(begin: "%r!", end: "![a-z]*"),
                Mode.new.apply(begin: "%r\\[", end: "\\][a-z]*"),
              ] of Mode
            ),
          ].concat([i_r_b__o_b_j_e_c_t]).concat(c_o_m_m_e_n_t__m_o_d_e_s),
          relevance: 0
        ),
      ].concat([i_r_b__o_b_j_e_c_t]).concat(c_o_m_m_e_n_t__m_o_d_e_s)

      s_u_b_s_t.contains = r_u_b_y__d_e_f_a_u_l_t__c_o_n_t_a_i_n_s
      p_a_r_a_m_s.contains = r_u_b_y__d_e_f_a_u_l_t__c_o_n_t_a_i_n_s

      s_i_m_p_l_e__p_r_o_m_p_t = "[>?]>"
      d_e_f_a_u_l_t__p_r_o_m_p_t = "[\\w#]+\\(\\w+\\):\\d+:\\d+[>*]"
      r_v_m__p_r_o_m_p_t = "(\\w+-)?\\d+\\.\\d+\\.\\d+(p\\d+)?[^\\d][^>]+>"

      i_r_b__d_e_f_a_u_l_t = [
        Mode.new.apply(
          begin: /^\s*=>/,
          starts: Mode.new.apply(end: "$", contains: r_u_b_y__d_e_f_a_u_l_t__c_o_n_t_a_i_n_s)
        ),
        Mode.new.apply(
          class_name: "meta.prompt",
          begin: "^(" + s_i_m_p_l_e__p_r_o_m_p_t + "|" + d_e_f_a_u_l_t__p_r_o_m_p_t + "|" + r_v_m__p_r_o_m_p_t + ")(?=[ ])",
          starts: Mode.new.apply(
            end: "$",
            keywords: r_u_b_y__k_e_y_w_o_r_d_s,
            contains: r_u_b_y__d_e_f_a_u_l_t__c_o_n_t_a_i_n_s
          )
        ),
      ] of Mode

      c_o_m_m_e_n_t__m_o_d_e_s.unshift(i_r_b__o_b_j_e_c_t)

      Mode.new.apply(
        name: "Ruby",
        aliases: ["rb", "gemspec", "podspec", "thor", "irb"],
        keywords: r_u_b_y__k_e_y_w_o_r_d_s,
        illegal: /\/\*/,
        contains: ([hljs.shebang(binary: "ruby")] of Mode)
          .concat(i_r_b__d_e_f_a_u_l_t)
          .concat(c_o_m_m_e_n_t__m_o_d_e_s)
          .concat(r_u_b_y__d_e_f_a_u_l_t__c_o_n_t_a_i_n_s)
      )
    end
  end

  Languages.register("ruby", ->(hljs : HLJS) { RubyLang.defined(hljs) })
end
