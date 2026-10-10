// Генератор списков для src/highlight/languages/swift.cr
// из oracle/vendor/highlight.js/lib/languages/swift.js.
// Запуск: node spec/gen_swift_lists.js
const fs = require("fs");
const src = fs.readFileSync("oracle/vendor/highlight.js/lib/languages/swift.js", "utf8");

// блок `const NAME = [ ... ];` (до строки `function swift`)
function extractBlock(name) {
  const re = new RegExp("const " + name + " = \\[([\\s\\S]*?)\\n\\]");
  const m = src.match(re);
  if (!m) throw new Error("not found: " + name);
  return m[1].replace(/\/\/[^\n]*/g, "");
}

// элементы: строки 'x', regex /x/, concat-выражения (целиком)
function extractItems(name) {
  let body = extractBlock(name);
  body = body.replace(/concat\((?:[^()\\]|\\.|\([^()]*\))*\)/g, "@@CONCAT@@");
  return [...body.matchAll(/'(?:[^'\\]|\\.)*'|\/(?:[^\/\\\\]|\\.)+\/|@@CONCAT@@/g)].map((m) => m[0]);
}

function quote(s) { return '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'; }

function emitPlain(name, varName) {
  const items = extractItems(name);
  if (items.some((x) => !/^'[^']*'$/.test(x))) throw new Error("not plain: " + name);
  const words = items.map((x) => x.slice(1, -1));
  if (words.some((x) => !/^[A-Za-z0-9_#]+$/.test(x))) throw new Error("unsafe in " + name + ": " + words);
  return "    " + varName + " = %w[" + words.join(" ") + "]\n";
}

function emitMixed(name, varName) {
  const items = extractItems(name);
  const lines = ["    " + varName + " = ["];
  for (const it of items) {
    if (it.startsWith("'")) {
      lines.push("      " + quote(it.slice(1, -1)) + ",");
    } else if (it.startsWith("/")) {
      const body = it.slice(1, -1);
      if (/[#\u0080-\uffff]/.test(body) || !/^\/[^/]*\/$/.test(it)) {
        // небезопасно как литерал — как строка, но тогда теряется тип;
        // в swift.js таких нет, поэтому просто проверка
        throw new Error("unsafe regex item in " + name + ": " + it);
      }
      lines.push("      /" + body + "/,");
    } else if (it === "@@CONCAT@@") {
      lines.push("      @@CONCAT@@,");
    } else throw new Error("unknown item in " + name + ": " + it);
  }
  lines.push("    ] of String | Regex");
  return lines.join("\n") + "\n";
}

let code = "";
code += "# Порт lib/languages/swift.js (highlight.js 11.12.0).\n";
code += "# Списки извлечены из оригинала скриптом spec/gen_swift_lists.js.\n\n";
code += "module Highlight::Languages\n";
code += "  module Swift\n";
code += emitPlain("dotKeywords", "DOT_KEYWORDS_RAW");
code += emitPlain("optionalDotKeywords", "OPTIONAL_DOT_KEYWORDS_RAW");
code += emitPlain("keywordTypes", "KEYWORD_TYPES");
code += emitMixed("keywords", "KEYWORDS_MIXED");
code += emitPlain("literals", "LITERALS");
code += emitPlain("precedencegroupKeywords", "PRECEDENCEGROUP_KEYWORDS");
code += emitPlain("numberSignKeywords", "NUMBER_SIGN_KEYWORDS");
code += emitPlain("builtIns", "BUILT_INS");
code += emitMixed("keywordAttributes", "KEYWORD_ATTRIBUTES");
code += emitPlain("availabilityKeywords", "AVAILABILITY_KEYWORDS");

// concat-заглушки в KEYWORD_ATTRIBUTES заменяем на реальные выражения
code = code.replace(
  "      @@CONCAT@@,\n      \"discardableResult\",",
  "      \"convention\\\\((?:swift|block|c)\\\\\",",
);
code = code.replace(
  '      @@CONCAT@@,\n      "objc",',
  '      "objc\\\\(" + IDENTIFIER + "\\\\)",',
);
if (code.includes("@@CONCAT@@")) throw new Error("unhandled concat placeholder");
fs.writeFileSync("src/highlight/languages/swift.cr", code);
console.log("ok");
