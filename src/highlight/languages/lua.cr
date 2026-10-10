# Порт lib/languages/lua.js (highlight.js 11.12.0).

module Highlight::Languages
  module Lua
    def self.defined(hljs : HLJS) : Mode
      opening_long_bracket = "\\[=*\\["
      closing_long_bracket = "\\]=*\\]"
      long_brackets = Mode.new.apply(
        begin: opening_long_bracket,
        end: closing_long_bracket,
        contains: [Mode.self_marker] of Mode
      )
      comments = [
        hljs.comment("--(?!" + opening_long_bracket + ")", "$"),
        hljs.comment(
          "--" + opening_long_bracket,
          closing_long_bracket,
          Mode.new.apply(
            contains: [long_brackets] of Mode,
            relevance: 10
          )
        ),
      ] of Mode
      keywords = {} of String => KeywordsVal
      keywords["$pattern"] = UNDERSCORE_IDENT_RE
      keywords["literal"] = "true false nil"
      keywords["keyword"] = "and break do else elseif end for goto if in local global not or repeat return then until while"
      keywords["built_in"] =
        # Metatags and globals:
        "_G _ENV _VERSION __index __newindex __mode __call __metatable __tostring __len " +
        "__gc __add __sub __mul __div __mod __pow __concat __unm __eq __lt __le assert " +
        # Standard methods and properties:
        "collectgarbage dofile error getfenv getmetatable ipairs load loadfile loadstring " +
        "module next pairs pcall print rawequal rawget rawset require select setfenv " +
        "setmetatable tonumber tostring type unpack xpcall arg self " +
        # Library methods and properties (one line per library):
        "coroutine resume yield status wrap create running debug getupvalue " +
        "debug sethook getmetatable gethook setmetatable setlocal traceback setfenv getinfo setupvalue getlocal getregistry getfenv " +
        "io lines write close flush open output type read stderr stdin input stdout popen tmpfile " +
        "math log max acos huge ldexp pi cos tanh pow deg tan cosh sinh random randomseed frexp ceil floor rad abs sqrt modf asin min mod fmod log10 atan2 exp sin atan " +
        "os exit setlocale date getenv difftime remove time clock tmpname rename execute package preload loadlib loaded loaders cpath config path seeall " +
        "string sub upper len gfind rep find match char dump gmatch reverse byte format gsub lower " +
        "table setn insert getn foreachi maxn foreach concat sort remove"
      Mode.new.apply(
        name: "Lua",
        aliases: ["pluto"],
        keywords: keywords,
        contains: comments.concat([
          Mode.new.apply(
            class_name: "function",
            begin_keywords: "function",
            end: "\\)",
            contains: [
              MODES::TITLE_MODE.inherit(Mode.new.apply(begin: "([_a-zA-Z]\\w*\\.)*([_a-zA-Z]\\w*:)?[_a-zA-Z]\\w*")),
              Mode.new.apply(
                class_name: "params",
                begin: "\\(",
                ends_with_parent: true,
                contains: comments
              ),
            ].concat(comments)
          ),
          MODES::C_NUMBER_MODE,
          MODES::APOS_STRING_MODE,
          MODES::QUOTE_STRING_MODE,
          Mode.new.apply(
            class_name: "string",
            begin: opening_long_bracket,
            end: closing_long_bracket,
            contains: [long_brackets] of Mode,
            relevance: 5
          ),
        ] of Mode)
      )
    end
  end

  Languages.register("lua", ->(hljs : HLJS) { Lua.defined(hljs) })
end
