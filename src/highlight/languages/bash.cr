# Порт lib/languages/bash.js (highlight.js 11.12.0).

module Highlight::Languages
  module Bash
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      var_mode = Mode.new
      braced_var = Mode.new.apply(
        begin: /\$\{/,
        end: /\}/,
        contains: [
          Mode.self_marker,
          Mode.new.apply(
            begin: /:-/,
            contains: [var_mode] of Mode
          ), # default values
        ] of Mode
      )
      var_mode.apply(
        class_name: "variable",
        variants: [
          Mode.new.apply(begin: regex.concat(
            /\$[\w\d#@][\w\d_]*/,
            # negative look-ahead tries to avoid matching patterns that are not
            # Perl at all like $ident$, @ident@, etc.
            "(?![\\w\\d])(?![$])"
          )),
          braced_var,
        ] of Mode
      )

      subst = Mode.new.apply(
        class_name: "subst",
        begin: /\$\(/,
        end: /\)/,
        contains: [MODES::BACKSLASH_ESCAPE] of Mode
      )
      comment = hljs.comment(nil, nil).inherit(Mode.new.apply(
        match: [
          /(^|\s)/,
          /#.*$/,
        ] of String | Regex,
        scope: {"2" => "comment"}
      ))
      here_doc = Mode.new.apply(
        begin: /<<-?\s*(?=\w+)/,
        starts: Mode.new.apply(contains: [
          hljs.end_same_as_begin(Mode.new.apply(
            begin: /(\w+)/,
            end: /(\w+)/,
            class_name: "string"
          )),
        ] of Mode)
      )
      quote_string = Mode.new.apply(
        class_name: "string",
        begin: /"/,
        end: /"/,
        contains: [
          MODES::BACKSLASH_ESCAPE,
          var_mode,
          subst,
        ] of Mode
      )
      subst.contains.not_nil! << quote_string
      escaped_quote = Mode.new.apply(
        match: /\\"/
      )
      apos_string = Mode.new.apply(
        class_name: "string",
        begin: /'/,
        end: /'/
      )
      escaped_apos = Mode.new.apply(
        match: /\\'/
      )
      arithmetic = Mode.new.apply(
        begin: /\$?\(\(/,
        end: /\)\)/,
        contains: [
          Mode.new.apply(
            begin: /\d+#[0-9a-f]+/,
            class_name: "number"
          ),
          MODES::NUMBER_MODE,
          var_mode,
        ] of Mode
      )
      sh_like_shells = [
        "fish",
        "bash",
        "zsh",
        "sh",
        "csh",
        "ksh",
        "tcsh",
        "dash",
        "scsh",
      ]
      known_shebang = hljs.shebang(
        binary: "(" + sh_like_shells.join("|") + ")",
        relevance: 10
      )
      function = Mode.new.apply(
        class_name: "function",
        begin: /\w[\w\d_]*\s*\(\s*\)\s*\{/,
        return_begin: true,
        contains: [MODES::TITLE_MODE.inherit(Mode.new.apply(begin: /\w[\w\d_]*/))] of Mode,
        relevance: 0
      )

      keywords = [
        "if",
        "then",
        "else",
        "elif",
        "fi",
        "time",
        "for",
        "while",
        "until",
        "in",
        "do",
        "done",
        "case",
        "esac",
        "coproc",
        "function",
        "select",
      ]

      literals = [
        "true",
        "false",
      ]

      # to consume paths to prevent keyword matches inside them
      path_mode = Mode.new.apply(match: /(\/[a-z._-]+)+/)

      # http://www.gnu.org/software/bash/manual/html_node/Shell-Builtin-Commands.html
      shell_built_ins = [
        "break",
        "cd",
        "continue",
        "eval",
        "exec",
        "exit",
        "export",
        "getopts",
        "hash",
        "pwd",
        "readonly",
        "return",
        "shift",
        "test",
        "times",
        "trap",
        "umask",
        "unset",
      ]

      bash_built_ins = [
        "alias",
        "bind",
        "builtin",
        "caller",
        "command",
        "declare",
        "echo",
        "enable",
        "help",
        "let",
        "local",
        "logout",
        "mapfile",
        "printf",
        "read",
        "readarray",
        "source",
        "sudo",
        "type",
        "typeset",
        "ulimit",
        "unalias",
      ]

      zsh_built_ins = [
        "autoload",
        "bg",
        "bindkey",
        "bye",
        "cap",
        "chdir",
        "clone",
        "comparguments",
        "compcall",
        "compctl",
        "compdescribe",
        "compfiles",
        "compgroups",
        "compquote",
        "comptags",
        "comptry",
        "compvalues",
        "dirs",
        "disable",
        "disown",
        "echotc",
        "echoti",
        "emulate",
        "fc",
        "fg",
        "float",
        "functions",
        "getcap",
        "getln",
        "history",
        "integer",
        "jobs",
        "kill",
        "limit",
        "log",
        "noglob",
        "popd",
        "print",
        "pushd",
        "pushln",
        "rehash",
        "sched",
        "setcap",
        "setopt",
        "stat",
        "suspend",
        "ttyctl",
        "unfunction",
        "unhash",
        "unlimit",
        "unsetopt",
        "vared",
        "wait",
        "whence",
        "where",
        "which",
        "zcompile",
        "zformat",
        "zftp",
        "zle",
        "zmodload",
        "zparseopts",
        "zprof",
        "zpty",
        "zregexparse",
        "zsocket",
        "zstyle",
        "ztcp",
      ]

      gnu_core_utils = [
        "chcon",
        "chgrp",
        "chown",
        "chmod",
        "cp",
        "dd",
        "df",
        "dir",
        "dircolors",
        "ln",
        "ls",
        "mkdir",
        "mkfifo",
        "mknod",
        "mktemp",
        "mv",
        "realpath",
        "rm",
        "rmdir",
        "shred",
        "sync",
        "touch",
        "truncate",
        "vdir",
        "b2sum",
        "base32",
        "base64",
        "cat",
        "cksum",
        "comm",
        "csplit",
        "cut",
        "expand",
        "fmt",
        "fold",
        "head",
        "join",
        "md5sum",
        "nl",
        "numfmt",
        "od",
        "paste",
        "ptx",
        "pr",
        "sha1sum",
        "sha224sum",
        "sha256sum",
        "sha384sum",
        "sha512sum",
        "shuf",
        "sort",
        "split",
        "sum",
        "tac",
        "tail",
        "tr",
        "tsort",
        "unexpand",
        "uniq",
        "wc",
        "arch",
        "basename",
        "chroot",
        "date",
        "dirname",
        "du",
        "echo",
        "env",
        "expr",
        "factor",
        # "false", # keyword literal already
        "groups",
        "hostid",
        "id",
        "link",
        "logname",
        "nice",
        "nohup",
        "nproc",
        "pathchk",
        "pinky",
        "printenv",
        "printf",
        "pwd",
        "readlink",
        "runcon",
        "seq",
        "sleep",
        "stat",
        "stdbuf",
        "stty",
        "tee",
        "test",
        "timeout",
        # "true", # keyword literal already
        "tty",
        "uname",
        "unlink",
        "uptime",
        "users",
        "who",
        "whoami",
        "yes",
      ]

      Mode.new.apply(
        name: "Bash",
        aliases: [
          "sh",
          "zsh",
        ],
        keywords: {
          "$pattern" => "\\b[a-z][a-z0-9._-]+\\b",
          "keyword"  => keywords,
          "literal"  => literals,
          "built_in" => shell_built_ins.concat(bash_built_ins)
            .concat(["set", "shopt"]) # Shell modifiers
            .concat(zsh_built_ins).concat(gnu_core_utils),
        } of String => KeywordsVal,
        contains: [
          known_shebang,                            # to catch known shells and boost relevancy
          hljs.shebang,                             # to catch unknown shells but still highlight the shebang
          function,
          arithmetic,
          comment,
          here_doc,
          path_mode,
          quote_string,
          escaped_quote,
          apos_string,
          escaped_apos,
          var_mode,
        ] of Mode
      )
    end
  end

  Languages.register("bash", ->(hljs : HLJS) { Bash.defined(hljs) })
end
