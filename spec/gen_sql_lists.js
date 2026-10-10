// Генератор списков для src/highlight/languages/sql.cr
// из oracle/vendor/highlight.js/lib/languages/sql.js.
// Запуск: node spec/gen_sql_lists.js
const fs = require("fs");
const src = fs.readFileSync("oracle/vendor/highlight.js/lib/languages/sql.js", "utf8");

function extractList(name) {
  const re = new RegExp("const " + name + " = \\[([\\s\\S]*?)\\];");
  const m = src.match(re);
  if (!m) throw new Error("not found: " + name);
  const body = m[1].replace(/\/\/[^\n]*/g, "");
  return [...body.matchAll(/['"]([^'"]+)['"]/g)].map((x) => x[1]);
}

function emit(name) {
  const items = extractList(name);
  if (items.some((x) => !/^[A-Za-z0-9_ .-]+$/.test(x))) {
    throw new Error("unsafe item in " + name + ": " + items.find((x) => !/^[A-Za-z0-9_ .-]+$/.test(x)));
  }
  const lines = [];
  let line = "    " + name + " = [";
  for (const it of items) {
    const tok = '"' + it + '", ';
    if (line.length + tok.length > 76) {
      lines.push(line);
      line = "      ";
    }
    line += tok;
  }
  lines.push(line);
  return lines.join("\n").trimEnd().replace(/,$/, "]") + "\n";
}

let code = "";
code += "# Порт lib/languages/sql.js (highlight.js 11.12.0).\n";
code += "# Списки извлечены из оригинала скриптом spec/gen_sql_lists.js.\n\n";
code += "module Highlight::Languages\n";
code += "  module Sql\n";
for (const n of ["LITERALS", "MULTI_WORD_TYPES", "TYPES", "NON_RESERVED_WORDS", "RESERVED_WORDS", "RESERVED_FUNCTIONS", "POSSIBLE_WITHOUT_PARENS", "COMBOS"]) {
  code += emit(n);
}
fs.writeFileSync("src/highlight/languages/sql.cr", code);
console.log("ok");
