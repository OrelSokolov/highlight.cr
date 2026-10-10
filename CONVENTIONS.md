# Конвенции портирования языков highlight.js → highlight.cr

Цель: байт-в-байт совпадение вывода с highlight.js 11.12.0.
Оригиналы: `oracle/vendor/highlight.js/lib/languages/<name>.js`.
Эталон готового порта: `src/highlight/languages/ruby.cr`.

## Каркас файла

```crystal
# Порт lib/languages/<name>.js (highlight.js 11.12.0).

module Highlight::Languages
  module Xlang # Xlang, а не зарезервированные слова (Class, Object, ...на языках вроде java ок: JavaLang)
    def self.defined(hljs : HLJS) : Mode
      regex = RegexHelpers
      # ... локальные переменные вместо const: x_name = ...
      Mode.new.apply(
        name: "<Name>",
        aliases: [...],
        keywords: ...,
        contains: [...] of Mode,
      )
    end
  end

  Languages.register("<name>", ->(hljs : HLJS) { Xlang.defined(hljs) })
end
```

Имя модуля не должно конфликтовать: `Object`, `Class`, `Comparable`, `Enumerable`,
`Set`, `Signal`, `Process`, `File`, `IO`, `JSON`, `XML`, `System`, `Random`,
`Thread`, `Channel`, `Tuple`, `Regex` и т.п. — добавляйте суффикс `Lang`
(например `JavaLang`, `ObjectLang`).

## Соответствие API

| JS | Crystal |
|---|---|
| `hljs.COMMENT(a, b, opts)` | `hljs.comment(a, b, opt_mode)` — opts это `Mode.new.apply(...)` |
| `hljs.SHEBANG({binary: "x"})` | `hljs.shebang(binary: "x")` (прочие ключи — им. аргументы apply) |
| `hljs.END_SAME_AS_BEGIN(mode)` | `hljs.end_same_as_begin(mode)` |
| `hljs.BACKSLASH_ESCAPE` | `MODES::BACKSLASH_ESCAPE` (внутри языкового файла можно просто `Highlight::MODES::BACKSLASH_ESCAPE`) |
| `hljs.C_LINE_COMMENT_MODE` и др. | `MODES::C_LINE_COMMENT_MODE` |
| `hljs.IDENT_RE`/`UNDERSCORE_IDENT_RE`/`NUMBER_RE`/`C_NUMBER_RE`/`BINARY_NUMBER_RE`/`RE_STARTERS_RE`/`MATCH_NOTHING_RE` | константы `Highlight::IDENT_RE` и т.п. |
| `hljs.regex.concat/either/lookahead/optional/anyNumberOfTimes` | `regex.concat(...)` / `regex.either([...] of String|Regex)` / `regex.lookahead(...)` / `regex.optional(...)` / `regex.any_number_of_times(...)` |
- `hljs.getLanguage('c')` | `hljs.get_language("c")` |
| `hljs.inherit(a, b)` | `a.inherit(b_mode)` |
| `hljs.inherit(a, {contains: null, illegal: null, className: null})` | `a.inherit(mode, clear_contains: true, clear_illegal: true, clear_scope: true)` — явные JS-`null` нельзя передать значением, есть флаги очистки `clear_scope/clear_illegal/clear_contains/clear_variants/clear_starts` |
| ключи режимов camelCase | snake_case: `className`→`class_name`, `beginKeywords`→`begin_keywords`, `beginScope`→`begin_scope`, `endScope`→`end_scope`, `endsWithParent`→`ends_with_parent`, `endsParent`→`ends_parent`, `excludeBegin`→`exclude_begin`, `excludeEnd`→`exclude_end`, `returnBegin`→`return_begin`, `returnEnd`→`return_end`, `self` в contains — НЕ РЕАЛИЗОВАН (если встретится — `Mode.self_marker`) |
| `subLanguage: 'xml'` | `sub_language: "xml"` |
| `case_insensitive`, `unicodeRegex`, `disableAutodetect`, `supersetOf`, `aliases`, `name`, `illegal`, `variants`, `match`, `beforeMatch`→`before_match`, `starts`, `keywords`, `relevance`, `scope`, `begin`, `end`, `contains` | одноимённо snake_case |
| `scope: {2: "title.class"}` | `scope: {"2" => "title.class"}` (ключи — строки!) |
| `match: [re1, re2]` | `match: [re1, re2]` (массив RegExp/строк) |
| `keywords: 'a b c'` | `keywords: "a b c"` |
| `keywords: {keyword: [...], $pattern: re}` | `kw = {} of String => KeywordsVal; kw["keyword"] = [...]; kw["$pattern"] = "\\w+"` |
| `"on:begin": (m, resp) => ...` | `on_begin: ->(m : EnhancedMatch, resp : Response) { ...; nil }` |
| `"on:end"` | `on_end: Proc(EnhancedMatch, Response, Nil)` |

`Mode.new.apply(**fields)` — устанавливает переданные поля. Для полей не из
списка выше (например `exports: {preprocessor: ...}`) — `property` на Mode уже
есть: `exports` типа `Hash(String, Mode)?`.

## Регексы

- JS-литерал `/abc/` → Crystal-литерал `/abc/` или `%r(...)` — если в паттерне
  есть `/`, Crystal требует `%r()` или `\/` (в т.ч. внутри `[]`!).
- `#` внутри regex-литерала Crystal ненадёжен (литерал может обрезаться на
  `#` или `#{` даёт интерполяцию) — паттерны с `#` пишите строкой:
  `"(@|#(un)?)available"`, `"[./?&#]"`, `"#\\w+"`. Строки-паттерны с `#{`
  пишите `%q(...)` (пример: заголовки markdown `%q(^#{1,6})`).
- Backreferences (`\1`) и `\uXXXX` — только строкой: `"\\1"`, `"[\\u00A1-\\u00A7]"`
  (литерал `\u` не компилируется, а JSRegex.translate сам переводит `\uXXXX`
  в PCRE `\x{...}`).
- Строковые паттерны `'\\d+'` → `"\\d+"` (в двойных кавычках `\\` = `\`).
- Backtick-template `` `...` `` в паттернах — обычная строка Crystal с `` ` ``.
- Внутри символьных классов допустимы `\\w`/`\\d` (движок раскрывает их сам);
  `\\W`/`\\D`/`\\B` внутри классов не поддерживаются — если оригинал их
  использует, раскройте вручную (`[^A-Za-z0-9_]` и т.п. для всего класса).

## Длинные списки имён

Списки вида HTML_TAGS/ATTRIBUTES/PSEUDO_CLASSES (css, sql, swift — сотни
элементов) НЕ копируются руками: они извлекаются из js-оригинала генератором
(`spec/gen_css_lists.js`, `gen_sql_lists.js`, `gen_swift_lists.js`) в шапку
файла языка, логика дописывается вручную ниже. Генераторы лежат в spec/
рядом со спеками и перезапускаются `node spec/gen_<lang>_lists.js`.
`.sort().reverse()` оригинала → `.sort.reverse` на константе (порядок по
байтам на ASCII совпадает с JS sort по UTF-16 кодам).

## Ключевые механики

- Локальные «константы» JS (`const STRING = {...}`) — локальные переменные
  Crystal (snake_case). НЕ Crystal-константы (внутри def нельзя).
- Порядок выражений важен: мутации вида `SUBST.contains = DEFAULT_CONTAINS`
  и `arr.unshift(X)` делайте ровно там же, где в оригинале.
- `variants: [{...}, {...}]` — массив `Mode` с только отличающимися полями.
- `keywords`-хэш: `{} of String => KeywordsVal`, значения — `Array(String)`
  или `String` или вложенный хэш (не обязан).
- `contains`-массивы: пишите `] of Mode` если массив может быть пуст или
  состоит из переменных-Mode; литералы из Mode можно без аннотации.
- Совместное использование одного объекта режима в нескольких местах —
  норм (как в JS, ссылки общие).
- Колбэки: `m` это `EnhancedMatch`: `m.index` (Int32), `m[0]`/`m[1]`...
  (`String?`), `m.input`; `resp.ignore_match`, `resp.data["k"] = v`.
  Последнее выражение прока — `nil`.
- `hljs.get_language("...")` может вернуть `Mode?` — при `.exports` нужен
  `.not_nil!`. Если язык зависит от другого (например typescript определяет
  javascript внутри себя), переносите зависимость так же, как в оригинале.

## Проверка

```
cd <шард> && crystal spec -e '<lang>'    # только кейсы этого языка (фильтр по "lang_oracle <lang>")
```

Кейсы `<lang>_html` и `<lang>_relevance` должны проходить байт-в-байт.
Готовность: `crystal spec -e '<lang>'` зелёный, файл компилируется без
warning-ов о неиспользуемых переменных не будет — это ок для локальных переменных.
