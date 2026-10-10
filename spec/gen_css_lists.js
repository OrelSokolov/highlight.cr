// Генератор списков имён для src/highlight/languages/css.cr
// из оригинального oracle/vendor/highlight.js/lib/languages/css.js.
// Запуск: node spec/gen_css_lists.js (перезаписывает css.cr, списочная часть)
const fs = require("fs");
const src = fs.readFileSync("oracle/vendor/highlight.js/lib/languages/css.js", "utf8");

function extractList(name) {
  const re = new RegExp(
    "const " + name + " = \\[([\\s\\S]*?)\\](\\.sort\\(\\)\\.reverse\\(\\))?",
  );
  const m = src.match(re);
  if (!m) throw new Error("not found: " + name);
  return { items: [...m[1].matchAll(/'([^']+)'/g)].map((x) => x[1]), sorted: !!m[2] };
}

function emit(name, varName, sorted) {
  const { items } = extractList(name);
  if (items.some((x) => !/^[A-Za-z0-9_-]+$/.test(x))) {
    throw new Error("unsafe item in " + name);
  }
  const lines = [];
  let line = "    " + varName + " = %w[";
  for (const it of items) {
    if (line.length + it.length + 1 > 78) {
      lines.push(line);
      line = "      ";
    }
    line += it + " ";
  }
  lines.push(line);
  return lines.join("\n").trimEnd() + "]" + (sorted ? ".sort.reverse" : "") + "\n";
}

let code = "";
code += "# Порт lib/languages/css.js (highlight.js 11.12.0).\n";
code += "# Списки имён сгенерированы из оригинала скриптом spec/gen_css_lists.js,\n";
code += "# не вручную. `.sort.reverse` = JS `.sort().reverse()`:\n";
code += "# длинные имена должны идти раньше коротких при сборке в альтернатив.\n\n";
code += "module Highlight::Languages\n";
code += "  module Css\n";
code += emit("HTML_TAGS", "HTML_TAGS", false);
code += emit("SVG_TAGS", "SVG_TAGS", false);
code += "    TAGS = HTML_TAGS + SVG_TAGS\n";
code += emit("MEDIA_FEATURES", "MEDIA_FEATURES", true);
code += emit("PSEUDO_CLASSES", "PSEUDO_CLASSES", true);
code += emit("PSEUDO_ELEMENTS", "PSEUDO_ELEMENTS", true);
code += emit("ATTRIBUTES", "ATTRIBUTES", true);
fs.writeFileSync("src/highlight/languages/css.cr", code);
console.log("written", code.length, "bytes");
