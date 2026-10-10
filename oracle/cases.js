#!/usr/bin/env node
// Oracle cases for highlight.cr — порт highlight.js 11.12.0.
//
// Запуск против ОРИГИНАЛЬНОЙ библиотеки (oracle-first):
//   node oracle/cases.js > oracle/expected.yml
//
// Формат как в остальных шардах: "<case_id>\t<value>", многострочные
// значения — escape-протокол \n/\t/\r/\\.

const hljs = require('./vendor/highlight.js/lib/common');
const fs = require('fs');
const snippet = (name) => fs.readFileSync(`${__dirname}/snippets/${name}`, 'utf8');

function esc(v) {
  return String(v)
    .replace(/\\/g, '\\\\')
    .replace(/\n/g, '\\n')
    .replace(/\t/g, '\\t')
    .replace(/\r/g, '\\r');
}

function caseRun(id, value) {
  console.log(`${id}\t${esc(value)}`);
}

function err(fn) {
  try {
    const r = fn();
    return `NO_ERROR ${esc(r)}`;
  } catch (e) {
    return `${e.constructor.name}: ${e.message}`;
  }
}

// --- Ruby ------------------------------------------------------------------

const RUBY_SNIPPET = snippet('ruby_sample.rb');

caseRun("ruby_html", hljs.highlight(RUBY_SNIPPET, { language: 'ruby' }).value);
caseRun("ruby_relevance", hljs.highlight(RUBY_SNIPPET, { language: 'ruby' }).relevance);

const RUBY_HEREDOC = snippet('ruby_heredoc.rb');
caseRun("ruby_heredoc", hljs.highlight(RUBY_HEREDOC, { language: 'ruby' }).value);
caseRun("ruby_heredoc_relevance", hljs.highlight(RUBY_HEREDOC, { language: 'ruby' }).relevance);

const RUBY_IRB = snippet('ruby_irb.txt');
caseRun("ruby_irb", hljs.highlight(RUBY_IRB, { language: 'ruby' }).value);

caseRun("ruby_alias_rb", hljs.highlight("x = 1", { language: 'rb' }).language);
caseRun("ruby_illegal_ok", hljs.highlight("a /* b", { language: 'ruby', ignoreIllegals: true }).illegal);
caseRun("ruby_illegal_strict", hljs.highlight("a /* b", { language: 'ruby', ignoreIllegals: false }).illegal);

// --- Остальные языки common-набора -------------------------------------------

const LANG_SNIPPETS = [
  ['xml', 'xml_sample.xml'],
  ['bash', 'bash_sample.sh'],
  ['c', 'c_sample.c'],
  ['cpp', 'cpp_sample.cpp'],
  ['csharp', 'csharp_sample.cs'],
  ['css', 'css_sample.css'],
  ['markdown', 'markdown_sample.md'],
  ['diff', 'diff_sample.diff'],
  ['go', 'go_sample.go'],
  ['graphql', 'graphql_sample.graphql'],
  ['ini', 'ini_sample.ini'],
  ['java', 'java_sample.java'],
  ['javascript', 'javascript_sample.js'],
  ['json', 'json_sample.json'],
  ['kotlin', 'kotlin_sample.kt'],
  ['less', 'less_sample.less'],
  ['lua', 'lua_sample.lua'],
  ['makefile', 'makefile_sample.mk'],
  ['perl', 'perl_sample.pl'],
  ['objectivec', 'objectivec_sample.m'],
  ['php', 'php_sample.php'],
  ['php-template', 'php_template_sample.php'],
  ['plaintext', 'plaintext_sample.txt'],
  ['python', 'python_sample.py'],
  ['python-repl', 'python_repl_sample.txt'],
  ['r', 'r_sample.r'],
  ['rust', 'rust_sample.rs'],
  ['scss', 'scss_sample.scss'],
  ['shell', 'shell_sample.sh'],
  ['sql', 'sql_sample.sql'],
  ['swift', 'swift_sample.swift'],
  ['yaml', 'yaml_sample.yaml'],
  ['typescript', 'typescript_sample.ts'],
  ['vbnet', 'vbnet_sample.vb'],
  ['wasm', 'wasm_sample.wat'],
];

for (const [lang, file] of LANG_SNIPPETS) {
  const code = snippet(file);
  caseRun(`${lang}_html`, hljs.highlight(code, { language: lang }).value);
  caseRun(`${lang}_relevance`, hljs.highlight(code, { language: lang }).relevance);
}

// --- Движок / API -------------------------------------------------------------

caseRun("list_languages", hljs.listLanguages().join(','));
caseRun("get_language_missing", hljs.getLanguage('nope')?.name ?? "MISSING");
caseRun("get_language_alias", hljs.getLanguage('js').name);
caseRun("get_language_case", hljs.getLanguage('Ruby').name);
caseRun("auto_detection_plaintext_off", hljs.autoDetection('plaintext'));
caseRun("auto_detection_ruby_on", hljs.autoDetection('ruby'));
caseRun("unknown_lang_error", err(() => hljs.highlight('x = 1', { language: 'doesnotexist' }).value).replace(/^Error: /, ''));

const autoGo = hljs.highlightAuto(snippet('go_autodetect_input.txt'));
caseRun("auto_go_lang", autoGo.language);
caseRun("auto_go_relevance", autoGo.relevance);
caseRun("auto_go_second", autoGo.secondBest.language);
caseRun("auto_go_value", autoGo.value);

const autoPy = hljs.highlightAuto(snippet('python_autodetect_input.txt'));
caseRun("auto_py_lang", autoPy.language);
caseRun("auto_py_relevance", autoPy.relevance);
caseRun("auto_py_second", autoPy.secondBest.language);

const autoBash = hljs.highlightAuto(snippet('bash_autodetect_input.txt'));
caseRun("auto_bash_lang", autoBash.language);
caseRun("auto_bash_relevance", autoBash.relevance);

caseRun("auto_plaintext_wins", hljs.highlightAuto("just some words and nothing else here").language);
caseRun("auto_subset", hljs.highlightAuto("def f():\n  return 1", ['python', 'ruby', 'bash']).language);
caseRun("auto_empty_lang", hljs.highlightAuto("").language ?? "null");
caseRun("auto_empty_relevance", hljs.highlightAuto("").relevance);
caseRun("auto_empty_value", hljs.highlightAuto("").value);

// автодетект html-страницы с вложенными js/css (subLanguage)
const HTML_EMBED = `<!DOCTYPE html>
<html>
<head>
<style type="text/css">
  .title { color: red; }
</style>
<script>
  document.title = "привет";
  if (a > b) console.log(\`tpl \${a}\`);
</script>
</head>
<body onload="init()">
  <p class="title">Текст &amp; <b>жирный</b></p>
  <!-- комментарий -->
</body>
</html>`;
caseRun("html_embed_html", hljs.highlight(HTML_EMBED, { language: 'xml' }).value);
caseRun("html_embed_relevance", hljs.highlight(HTML_EMBED, { language: 'xml' }).relevance);
caseRun("auto_html_lang", hljs.highlightAuto(HTML_EMBED).language);

// newInstance + configure(classPrefix)
const prefixed = hljs.newInstance();
prefixed.configure({ classPrefix: 'code-' });
prefixed.registerLanguage('ruby', require('./vendor/highlight.js/lib/languages/ruby'));
caseRun("custom_prefix", prefixed.highlight("def f; end", { language: 'ruby' }).value);
caseRun("custom_prefix_isolated", hljs.listLanguages().length);

caseRun("version", hljs.versionString);

// ignoreIllegals=false с реальным illegal-матчем
caseRun("c_illegal_strict_value", hljs.highlight('int a = `back`;', { language: 'c', ignoreIllegals: false }).value);
caseRun("c_illegal_strict_flag", hljs.highlight('int a = `back`;', { language: 'c', ignoreIllegals: false }).illegal);
caseRun("c_illegal_relaxed", hljs.highlight('int a = `back`;', { language: 'c', ignoreIllegals: true }).illegal);

// пустая строка / только текст
caseRun("empty_code", hljs.highlight("", { language: 'ruby' }).value);
caseRun("only_newline", hljs.highlight("\n", { language: 'ruby' }).value);

// keywords с |score и спец-наборы внутри Markdown (вложенный html)
caseRun("markdown_html_inline", hljs.highlight("текст <b>жирный</b> и *курсив*", { language: 'markdown' }).value);

// регистронезависимые ключевые слова (sql)
caseRun("sql_case_insensitive", hljs.highlight("SELECT NAME FROM USERS WHERE ID = 1;", { language: 'sql' }).value);

