# Порт lib/languages/perl.js (highlight.js 11.12.0).

module Highlight::Languages
  module Perl
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      keywords = [
        "abs", "accept", "alarm", "and", "atan2", "bind", "binmode", "bless",
        "break", "caller", "chdir", "chmod", "chomp", "chop", "chown", "chr",
        "chroot", "class", "close", "closedir", "connect", "continue", "cos",
        "crypt", "dbmclose", "dbmopen", "defined", "delete", "die", "do",
        "dump", "each", "else", "elsif", "endgrent", "endhostent",
        "endnetent", "endprotoent", "endpwent", "endservent", "eof", "eval",
        "exec", "exists", "exit", "exp", "fcntl", "field", "fileno", "flock",
        "for", "foreach", "fork", "format", "formline", "getc", "getgrent",
        "getgrgid", "getgrnam", "gethostbyaddr", "gethostbyname",
        "gethostent", "getlogin", "getnetbyaddr", "getnetbyname",
        "getnetent", "getpeername", "getpgrp", "getpriority",
        "getprotobyname", "getprotobynumber", "getprotoent", "getpwent",
        "getpwnam", "getpwuid", "getservbyname", "getservbyport",
        "getservent", "getsockname", "getsockopt", "given", "glob", "gmtime",
        "goto", "grep", "gt", "hex", "if", "index", "int", "ioctl", "join",
        "keys", "kill", "last", "lc", "lcfirst", "length", "link", "listen",
        "local", "localtime", "log", "lstat", "lt", "ma", "map", "method",
        "mkdir", "msgctl", "msgget", "msgrcv", "msgsnd", "my", "ne", "next",
        "no", "not", "oct", "open", "opendir", "or", "ord", "our", "pack",
        "package", "pipe", "pop", "pos", "print", "printf", "prototype",
        "push", "q|0", "qq", "quotemeta", "qw", "qx", "rand", "read",
        "readdir", "readline", "readlink", "readpipe", "recv", "redo", "ref",
        "rename", "require", "reset", "return", "reverse", "rewinddir",
        "rindex", "rmdir", "say", "scalar", "seek", "seekdir", "select",
        "semctl", "semget", "semop", "send", "setgrent", "sethostent",
        "setnetent", "setpgrp", "setpriority", "setprotoent", "setpwent",
        "setservent", "setsockopt", "shift", "shmctl", "shmget", "shmread",
        "shmwrite", "shutdown", "sin", "sleep", "socket", "socketpair",
        "sort", "splice", "split", "sprintf", "sqrt", "srand", "stat",
        "state", "study", "sub", "substr", "symlink", "syscall", "sysopen",
        "sysread", "sysseek", "system", "syswrite", "tell", "telldir", "tie",
        "tied", "time", "times", "tr", "truncate", "uc", "ucfirst", "umask",
        "undef", "unless", "unlink", "unpack", "unshift", "untie", "until",
        "use", "utime", "values", "vec", "wait", "waitpid", "wantarray",
        "warn", "when", "while", "write", "x|0", "xor", "y|0",
      ]

      # https://perldoc.perl.org/perlre#Modifiers
      regex_modifiers = /[dualxmsipngr]{0,12}/ # aa and xx are valid, making max length 12
      perl_keywords = {
        "$pattern" => "[\\w.]+",
        "keyword"  => keywords.join(" "),
      } of String => KeywordsVal
      subst = Mode.new.apply(
        class_name: "subst",
        begin: "[$@]\\{",
        end: "\\}",
        keywords: perl_keywords
      )
      method = Mode.new.apply(
        begin: /->\{/,
        end: /\}/
        # contains defined later
      )
      attr = Mode.new.apply(
        scope: "attr",
        match: /\s+:\s*\w+(\s*\(.*?\))?/
      )
      var = Mode.new.apply(
        scope: "variable",
        variants: [
          Mode.new.apply(begin: /\$\d/),
          Mode.new.apply(begin: regex.concat(
            /[$%@](?!")(\^\w\b|#\w+(::\w+)*|\{\w+\}|\w+(::\w*)*)/,
            # negative look-ahead tries to avoid matching patterns that are not
            # Perl at all like $ident$, @ident@, etc.
            "(?![A-Za-z])(?![@$%])"
          )),
          Mode.new.apply(
            # Only $= is a special Perl variable and one can't declare @= or %=.
            begin: /[$%@](?!")[^\s\w{=]|\$=/,
            relevance: 0
          ),
        ] of Mode,
        contains: [attr] of Mode
      )
      number = Mode.new.apply(
        class_name: "number",
        variants: [
          # decimal numbers:
          # include the case where a number starts with a dot (eg. .9), and
          # the leading 0? avoids mixing the first and second match on 0.x cases
          Mode.new.apply(match: /0?\.[0-9][0-9_]+\b/),
          # include the special versioned number (eg. v5.38)
          Mode.new.apply(match: /\bv?(0|[1-9][0-9_]*(\.[0-9_]+)?|[1-9][0-9_]*)\b/),
          # non-decimal numbers:
          Mode.new.apply(match: /\b0[0-7][0-7_]*\b/),
          Mode.new.apply(match: /\b0x[0-9a-fA-F][0-9a-fA-F_]*\b/),
          Mode.new.apply(match: /\b0b[0-1][0-1_]*\b/),
        ] of Mode,
        relevance: 0
      )
      string_contains = [
        MODES::BACKSLASH_ESCAPE,
        subst,
        var,
      ] of Mode
      regex_delims = [
        /!/,
        /\//,
        /\|/,
        /\?/,
        /'/,
        /"/, # valid but infrequent and weird
        /#/, # valid but infrequent and weird
      ] of Regex

      paired_double_re = ->(prefix : String | Regex, open : String | Regex, close : String | Regex) {
        middle = close == "\\1" ? close : regex.concat(close, open)
        regex.concat(
          regex.concat("(?:", prefix, ")"),
          open,
          /(?:\\.|[^\\\/])*?/,
          middle,
          /(?:\\.|[^\\\/])*?/,
          close,
          regex_modifiers
        )
      }
      paired_re = ->(prefix : String | Regex, open : String | Regex, close : String | Regex) {
        regex.concat(
          regex.concat("(?:", prefix, ")"),
          open,
          /(?:\\.|[^\\\/])*?/,
          close,
          regex_modifiers
        )
      }

      perl_default_contains = [
        var,
        MODES::HASH_COMMENT_MODE,
        hljs.comment(
          /^=\w/,
          /=cut/,
          Mode.new.apply(ends_with_parent: true)
        ),
        method,
        Mode.new.apply(
          class_name: "string",
          contains: string_contains,
          variants: [
            Mode.new.apply(begin: "q[qwxr]?\\s*\\(", end: "\\)", relevance: 5),
            Mode.new.apply(begin: "q[qwxr]?\\s*\\[", end: "\\]", relevance: 5),
            Mode.new.apply(begin: "q[qwxr]?\\s*\\{", end: "\\}", relevance: 5),
            Mode.new.apply(begin: "q[qwxr]?\\s*\\|", end: "\\|", relevance: 5),
            Mode.new.apply(begin: "q[qwxr]?\\s*<", end: ">", relevance: 5),
            Mode.new.apply(begin: "qw\\s+q", end: "q", relevance: 5),
            Mode.new.apply(begin: "'", end: "'", contains: [MODES::BACKSLASH_ESCAPE] of Mode),
            Mode.new.apply(begin: "\"", end: "\""),
            Mode.new.apply(begin: "`", end: "`", contains: [MODES::BACKSLASH_ESCAPE] of Mode),
            Mode.new.apply(begin: /\{\w+\}/, relevance: 0),
            Mode.new.apply(begin: "-?\\w+\\s*=>", relevance: 0),
          ] of Mode
        ),
        number,
        # regexp container
        Mode.new.apply(
          begin: "(\\/\\/|" + RE_STARTERS_RE + "|\\b(split|return|print|reverse|grep)\\b)\\s*",
          keywords: "split return print reverse grep",
          relevance: 0,
          contains: [
            MODES::HASH_COMMENT_MODE,
            Mode.new.apply(
              class_name: "regexp",
              variants: [
                # allow matching common delimiters
                Mode.new.apply(begin: paired_double_re.call("s|tr|y", regex.either(regex_delims, capture: true), "\\1")),
                # and then paired delmis
                Mode.new.apply(begin: paired_double_re.call("s|tr|y", "\\(", "\\)")),
                Mode.new.apply(begin: paired_double_re.call("s|tr|y", "\\[", "\\]")),
                Mode.new.apply(begin: paired_double_re.call("s|tr|y", "\\{", "\\}")),
              ] of Mode,
              relevance: 2
            ),
            Mode.new.apply(
              class_name: "regexp",
              variants: [
                # could be a comment in many languages so do not count
                # as relevant
                Mode.new.apply(begin: /(m|qr)\/\//, relevance: 0),
                # prefix is optional with /regex/
                Mode.new.apply(begin: paired_re.call("(?:m|qr)?", /\//, /\//)),
                # allow matching common delimiters
                Mode.new.apply(begin: paired_re.call("m|qr", regex.either(regex_delims, capture: true), "\\1")),
                # allow common paired delmins
                Mode.new.apply(begin: paired_re.call("m|qr", /\(/, /\)/)),
                Mode.new.apply(begin: paired_re.call("m|qr", /\[/, /\]/)),
                Mode.new.apply(begin: paired_re.call("m|qr", /\{/, /\}/)),
              ] of Mode
            ),
          ] of Mode
        ),
        Mode.new.apply(
          class_name: "function",
          begin_keywords: "sub method",
          end: "(\\s*\\(.*?\\))?[;{]",
          exclude_end: true,
          relevance: 5,
          contains: [MODES::TITLE_MODE, attr] of Mode
        ),
        Mode.new.apply(
          class_name: "class",
          begin_keywords: "class",
          end: "[;{]",
          exclude_end: true,
          relevance: 5,
          contains: [MODES::TITLE_MODE, attr, number] of Mode
        ),
        Mode.new.apply(
          begin: "-\\w\\b",
          relevance: 0
        ),
        Mode.new.apply(
          begin: "^__DATA__$",
          end: "^__END__$",
          sub_language: "mojolicious",
          contains: [
            Mode.new.apply(
              begin: "^@@.*",
              end: "$",
              class_name: "comment"
            ),
          ] of Mode
        ),
      ] of Mode
      subst.contains = perl_default_contains
      method.contains = perl_default_contains

      Mode.new.apply(
        name: "Perl",
        aliases: [
          "pl",
          "pm",
        ],
        keywords: perl_keywords,
        contains: perl_default_contains
      )
    end
  end

  Languages.register("perl", ->(hljs : HLJS) { Perl.defined(hljs) })
end
