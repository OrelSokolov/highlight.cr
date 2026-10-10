# highlight.cr

A [Crystal](https://crystal-lang.org) port of
[highlight.js](https://highlightjs.org) **11.12.0** — syntax highlighting
with **byte-for-byte identical HTML output** to the original JavaScript
library. No external dependencies.

Parity is verified by an oracle test suite: **96/96 test cases** produce
exactly the same HTML and relevance scores as the vendored
highlight.js 11.12.0 (`crystal spec spec/oracle_spec.cr`).

Since the emitted markup is identical (same `hljs-*` classes, same
structure), any highlight.js CSS theme works as-is.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  highlight_cr:
    github: OrelSokolov/highlight.cr
```

## Usage

```crystal
require "highlight_cr"

result = Highlight.highlight("puts 'hello'", "ruby")
puts result.value     # => puts <span class="hljs-string">'hello'</span>
puts result.relevance # => 1

# Auto-detection
auto = Highlight.highlight_auto("def foo; end")
puts auto.language    # => "ruby"

# Custom instance with only the languages you need
hljs = Highlight::HLJS.new
hljs.register_language("ruby")
result = hljs.highlight(code, "ruby")
```

## What is ported from the original library

| highlight.js feature                          | highlight.cr | Notes |
|-----------------------------------------------|:------------:|-------|
| Highlighting engine (mode compiler, `subLanguage`, continuations, relevance, illegal handling) | ✅ Ported | Full port of `lib/core.js` |
| HTML emitter (tiered scope class names, sublanguages) | ✅ Ported | Byte-identical output |
| Auto-detection (`highlightAuto`, `secondBest`, tie-breaking by registration order and superset rules) | ✅ Ported | |
| Common bundle — all 36 common languages        | ✅ Ported    | See list below |
| Language aliases (`registerAliases`)           | ✅ Ported    | |
| Plugins (`before:highlight`, `after:highlight`) | ✅ Ported   | |
| `configure` (`classPrefix`, `languages`)        | ✅ Ported    | |
| Token stream (`Highlight.tokens`)               | ✅ Ported    | Flat `{scope, text}` pairs for GUI consumers |
| DOM API (`highlightElement`, `highlightAll`, etc.) | ❌ Not ported | highlight.cr is a pure server-side library; there is no DOM in Crystal |
| Web Worker / browser builds                     | ❌ Not ported | N/A for Crystal |
| `__emitTokens`-style languages                  | ❌ Not ported | None exist in the common bundle |
| Languages beyond the common bundle              | ❌ Not ported | Can be ported following the same scheme (see `CONVENTIONS.md`) |
| CSS themes                                      | ➖ Reused    | Use any highlight.js theme; markup is identical |

## Languages (36)

xml, bash, c, cpp, csharp, css, markdown, diff, ruby, go, graphql, ini,
java, javascript, json, kotlin, less, lua, makefile, perl, objectivec, php,
php-template, plaintext, python, python-repl, r, rust, scss, shell, sql,
swift, yaml, typescript, vbnet, wasm

## Intentional differences from the JS original

- **Byte indices**: the engine operates on byte offsets (`byte_begin`,
  `byte_slice`) where the original uses UTF-16 code units; results match
  on all oracle snippets.
- **Regexes**: JS regexes are translated to PCRE2 by `JSRegex.translate` —
  `\w`/`\d`/`\b`/`\s` are expanded to JS (non-Unicode) semantics, `.` becomes
  `[^\n\r\u2028\u2029]`, `\uXXXX` becomes `\x{...}`.
- **Typing**: `relevance` is `Int32 | Float64` (integers render without
  `.0`); JS `null` overrides in `inherit` are expressed via `clear_*` flags.

## Development

```sh
crystal spec spec/oracle_spec.cr        # run the 96 oracle cases
node oracle/cases.js > oracle/expected.yml  # regenerate expectations
crystal run spec/diff_dbg.cr -- <lang> <snippet>  # find first output divergence
```

Architecture notes live in `PLAN.md`, porting conventions in
`CONVENTIONS.md`.
