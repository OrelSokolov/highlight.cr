# highlight.cr — статус и архитектура

Порт [highlight.js 11.12.0](https://highlightjs.org) на Crystal.
Цель: байт-в-байт совпадение HTML-вывода с оригиналом.

**Статус: порт завершён.** Все 36 языков common-набора + движок,
96/96 oracle-кейсов зелёные (`crystal spec spec/oracle_spec.cr`).

Оракул: `oracle/cases.js` (генератор кейсов против vendored
`oracle/vendor/highlight.js`), ожидания в `oracle/expected.yml`,
сниппеты в `oracle/snippets/`. Перегенерация:
`node oracle/cases.js > oracle/expected.yml`.

## Архитектура (`src/highlight/`)

- `core.cr` — `HLJS` (регистрация языков, `highlight`/`highlight_auto`,
  `_highlight` с continuation), компилятор языков (`compile_mode`,
  compiler extensions: scopeClassName, beginKeywords, match→begin,
  implicit `begin/end = /\B|\b/` для дочерних режимов, illegal-either),
  MultiRegex/ResumableMultiRegex.
- `session.cr` — порт замыкания `_highlight` из core.js: processLexeme,
  doBeginMatch/doEndMatch, subLanguage с `@continuations`,
  keyword-сканер, relevance (Int32|Float64, сессия копит Float64).
- `mode.cr` — `Mode` (все поля режимов snake_case), `inherit` с флагами
  `clear_*` для JS-`null`-перезаписей, `exports`, `label`.
- `modes.cr` — `MODES` (общие режимы: APOS/QUOTE_STRING_MODE,
  C_LINE/BLOCK_COMMENT_MODE, BACKSLASH_ESCAPE, …), общие RE-константы,
  `RegexHelpers` (concat/either/lookahead/optional/any_number_of_times —
  принимают String|Regex, отдают source-строки как hljs.regex).
- `js_regex.cr` — `JSRegex`: транслятор JS-регексов в PCRE2
  (`JSRegex.translate`) + exec c byte-индексами.
- `emitter.cr` — HTML-эмиттер (span-стек, add_sublanguage, закрытие узлов).
- `languages.cr` — реестр `Languages.register` + common-набор в порядке
  `lib/common.js` (порядок важен для автодетекта при ничьих).
- `languages/*.cr` — по файлу на язык, см. `CONVENTIONS.md`.

Спека `spec/oracle_spec.cr` зеркалит `oracle/cases.js`: кейсы
`<lang>_html`/`<lang>_relevance` против `oracle/expected.yml`
(escape-протокол `\n`/`\t`/`\r`/`\\`).

Инструменты: `spec/diff_dbg.cr` — поиск первого расхождения
(`crystal run spec/diff_dbg.cr -- <lang> <snippet>`); генераторы списков
`spec/gen_{css,sql,swift}_lists.js` (см. CONVENTIONS.md).

## Отличия от JS-оригинала (осознанные)

- **Индексы**: движок полностью байтовый (`byte_begin`/`byte_slice`), как
  JS-оригинал оперирует UTF-16 кодовыми единицами — на сниппетах оракула
  результаты совпадают; Crystal `MatchData#begin`/`String#[]` посимвольные
  и не используются.
- **Регексы**: `JSRegex.translate` разворачивает `\w`/`\d`/`\b`/`\s` в
  явные классы (JS без UCP-флага: `\w` = `[A-Za-z0-9_]`, `\s` без `\ufeff`),
  `.` вне классов — в `[^\n\r\u2028\u2029]` (JS 'm' не даёт DOTALL, а
  Crystal `Regex::Options::MULTILINE` = якоря+DOTALL — потому якоря `^$`
  транслируются отдельно, `$` матчит перед `\n`, но не перед `\r`),
  `\uXXXX` → `\x{...}`, `\1`-бэкрефы поддерживаются строковыми паттернами.
- **Типизация**: `relevance` — `Int32 | Float64` (в выводе целые без `.0`);
  явные `null` в `inherit` заменены флагами `clear_*`; `$pattern` в
  keywords-хэше хранится строкой (source), не Regex.
- **Не портировано**: DOM API оригинана (`highlightElement` и пр.),
  `__emitTokens`-языки (в common-наборе их нет), web-worker обвязка.
- **Идиомы Crystal**: `Array#concat` мутирует (для JS-спреда — `+`),
  `end: ""` трактуется как отсутствующий (JS falsy), regex-литералы с `#`
  или `/` внутри классов пишутся строками (см. CONVENTIONS.md).

## Языки (37)

xml, bash, c, cpp, csharp, css, markdown, diff, ruby, go, graphql, ini,
java, javascript, json, kotlin, less, lua, makefile, perl, objectivec, php,
php-template, plaintext, python, python-repl, r, rust, scss, shell, sql,
swift, yaml, typescript, vbnet, wasm — все портированы и зелёные.
Вне common-набора: erb (мост xml+ruby, регистрируется последним —
как явный `registerLanguage` поверх common-бандла).

Особенности портов: typescript вызывает свежий `JavascriptLang.defined`
и мутирует его (swapMode для shebang/use_strict); cpp берёт exports из c;
markdown содержит циклические BOLD/ITALIC через живые массивы contains;
scss/less переиспользуют списки из `Css`; списки css/sql/swift
сгенерированы скриптами из js-оригиналов.
