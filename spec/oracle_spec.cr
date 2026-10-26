require "spec"
require "../src/highlight"

# Зеркало oracle/cases.js: те же case id, сравнение с oracle/expected.yml.
# Формат: "<case_id>\t<escaped value>" (escape-протокол \n/\t/\r/\\).
# Перегенерация: node oracle/cases.js > oracle/expected.yml

module OracleSpec
  EXPECTED = {} of String => String

  def self.load
    File.read_lines(File.join(__DIR__, "..", "oracle", "expected.yml")).each do |line|
      key, _, value = line.partition('\t')
      EXPECTED[key] = value
    end
  end

  def self.escape_protocol(v : String) : String
    v.gsub("\\", "\\\\").gsub("\n", "\\n").gsub("\t", "\\t").gsub("\r", "\\r")
  end

  def self.check(case_id, value)
    load
    expected = EXPECTED[case_id]?
    fail "no expected value for #{case_id}" if expected.nil?
    actual = escape_protocol(value.to_s)
    fail "#{case_id}\n  expected: #{expected}\n  actual:   #{actual}" unless expected == actual
  end

  SNIPPET = ->(name : String) {
    File.read(File.join(__DIR__, "..", "oracle", "snippets", name))
  }

  LANG_SNIPPETS = [
    {"xml", "xml_sample.xml"}, {"bash", "bash_sample.sh"}, {"c", "c_sample.c"},
    {"cpp", "cpp_sample.cpp"}, {"csharp", "csharp_sample.cs"}, {"css", "css_sample.css"},
    {"markdown", "markdown_sample.md"}, {"diff", "diff_sample.diff"},
    {"ruby", "ruby_sample.rb"}, {"go", "go_sample.go"}, {"graphql", "graphql_sample.graphql"},
    {"ini", "ini_sample.ini"}, {"java", "java_sample.java"}, {"javascript", "javascript_sample.js"},
    {"json", "json_sample.json"}, {"kotlin", "kotlin_sample.kt"}, {"less", "less_sample.less"},
    {"lua", "lua_sample.lua"}, {"makefile", "makefile_sample.mk"}, {"perl", "perl_sample.pl"},
    {"objectivec", "objectivec_sample.m"}, {"php", "php_sample.php"},
    {"php-template", "php_template_sample.php"}, {"plaintext", "plaintext_sample.txt"},
    {"python", "python_sample.py"}, {"python-repl", "python_repl_sample.txt"},
    {"r", "r_sample.r"}, {"rust", "rust_sample.rs"}, {"scss", "scss_sample.scss"},
    {"shell", "shell_sample.sh"}, {"sql", "sql_sample.sql"}, {"swift", "swift_sample.swift"},
    {"yaml", "yaml_sample.yaml"}, {"typescript", "typescript_sample.ts"},
    {"vbnet", "vbnet_sample.vb"}, {"wasm", "wasm_sample.wat"},
    {"erb", "erb_sample.erb"},
    {"dockerfile", "dockerfile_sample.Dockerfile"},
  ]
end

OracleSpec.load
HL = Highlight.default

HTML_EMBED = <<-HTML
<!DOCTYPE html>
<html>
<head>
<style type="text/css">
  .title { color: red; }
</style>
<script>
  document.title = "привет";
  if (a > b) console.log(`tpl ${a}`);
</script>
</head>
<body onload="init()">
  <p class="title">Текст &amp; <b>жирный</b></p>
  <!-- комментарий -->
</body>
</html>
HTML

describe "ruby_extra" do
  it "ruby_heredoc" do
    code = OracleSpec::SNIPPET.call("ruby_heredoc.rb")
    OracleSpec.check("ruby_heredoc", HL.highlight(code, "ruby").value)
    OracleSpec.check("ruby_heredoc_relevance", HL.highlight(code, "ruby").relevance)
  end

  it "ruby_irb" do
    code = OracleSpec::SNIPPET.call("ruby_irb.txt")
    OracleSpec.check("ruby_irb", HL.highlight(code, "ruby").value)
  end

  it "ruby_alias_rb" do
    OracleSpec.check("ruby_alias_rb", HL.highlight("x = 1", "rb").language)
  end

  it "ruby_illegal" do
    OracleSpec.check("ruby_illegal_ok", HL.highlight("a /* b", "ruby", ignore_illegals: true).illegal)
    OracleSpec.check("ruby_illegal_strict", HL.highlight("a /* b", "ruby", ignore_illegals: false).illegal)
  end
end

# HTML + relevance для каждого языка common-набора.
describe "lang_oracle" do
  OracleSpec::LANG_SNIPPETS.each do |lang, file|
    it "#{lang}_html" do
      code = OracleSpec::SNIPPET.call(file)
      OracleSpec.check("#{lang}_html", HL.highlight(code, lang).value)
    end

    it "#{lang}_relevance" do
      code = OracleSpec::SNIPPET.call(file)
      OracleSpec.check("#{lang}_relevance", HL.highlight(code, lang).relevance)
    end
  end
end

describe "engine_oracle" do
  it "list_languages" do
    OracleSpec.check("list_languages", HL.list_languages.join(","))
  end

  it "get_language_missing" do
    OracleSpec.check("get_language_missing", HL.get_language("nope").try(&.name) || "MISSING")
  end

  it "get_language_alias" do
    OracleSpec.check("get_language_alias", HL.get_language("js").try(&.name))
  end

  it "get_language_case" do
    OracleSpec.check("get_language_case", HL.get_language("Ruby").try(&.name))
  end

  it "auto_detection_plaintext_off" do
    OracleSpec.check("auto_detection_plaintext_off", HL.auto_detection?("plaintext"))
  end

  it "auto_detection_ruby_on" do
    OracleSpec.check("auto_detection_ruby_on", HL.auto_detection?("ruby"))
  end

  it "unknown_lang_error" do
    msg = ""
    begin
      HL.highlight("x = 1", "doesnotexist")
    rescue ex
      msg = ex.message.to_s
    end
    OracleSpec.check("unknown_lang_error", msg)
  end

  it "auto_go" do
    code = OracleSpec::SNIPPET.call("go_autodetect_input.txt")
    r = HL.highlight_auto(code)
    OracleSpec.check("auto_go_lang", r.language)
    OracleSpec.check("auto_go_relevance", r.relevance)
    OracleSpec.check("auto_go_second", r.second_best.try(&.language))
    OracleSpec.check("auto_go_value", r.value)
  end

  it "auto_py" do
    code = OracleSpec::SNIPPET.call("python_autodetect_input.txt")
    r = HL.highlight_auto(code)
    OracleSpec.check("auto_py_lang", r.language)
    OracleSpec.check("auto_py_relevance", r.relevance)
    OracleSpec.check("auto_py_second", r.second_best.try(&.language))
  end

  it "auto_bash" do
    code = OracleSpec::SNIPPET.call("bash_autodetect_input.txt")
    r = HL.highlight_auto(code)
    OracleSpec.check("auto_bash_lang", r.language)
    OracleSpec.check("auto_bash_relevance", r.relevance)
  end

  it "auto_plaintext_wins" do
    OracleSpec.check("auto_plaintext_wins", HL.highlight_auto("just some words and nothing else here").language)
  end

  it "auto_subset" do
    OracleSpec.check("auto_subset", HL.highlight_auto("def f():\n  return 1", ["python", "ruby", "bash"]).language)
  end

  it "auto_empty" do
    r = HL.highlight_auto("")
    OracleSpec.check("auto_empty_lang", r.language || "null")
    OracleSpec.check("auto_empty_relevance", r.relevance)
    OracleSpec.check("auto_empty_value", r.value)
  end

  it "html_embed" do
    OracleSpec.check("html_embed_html", HL.highlight(HTML_EMBED, "xml").value)
    OracleSpec.check("html_embed_relevance", HL.highlight(HTML_EMBED, "xml").relevance)
    OracleSpec.check("auto_html_lang", HL.highlight_auto(HTML_EMBED).language)
  end

  it "custom_prefix" do
    prefixed = HL.new_instance
    prefixed.configure(class_prefix: "code-")
    prefixed.register_language("ruby", Highlight::Languages.language_fn("ruby").not_nil!)
    OracleSpec.check("custom_prefix", prefixed.highlight("def f; end", "ruby").value)
    OracleSpec.check("custom_prefix_isolated", HL.list_languages.size)
  end

  it "version" do
    OracleSpec.check("version", HL.version_string)
  end

  it "c_illegal" do
    OracleSpec.check("c_illegal_strict_value", HL.highlight("int a = `back`;", "c", ignore_illegals: false).value)
    OracleSpec.check("c_illegal_strict_flag", HL.highlight("int a = `back`;", "c", ignore_illegals: false).illegal)
    OracleSpec.check("c_illegal_relaxed", HL.highlight("int a = `back`;", "c", ignore_illegals: true).illegal)
  end

  it "empty_code" do
    OracleSpec.check("empty_code", HL.highlight("", "ruby").value)
    OracleSpec.check("only_newline", HL.highlight("\n", "ruby").value)
  end

  it "markdown_html_inline" do
    OracleSpec.check("markdown_html_inline", HL.highlight("текст <b>жирный</b> и *курсив*", "markdown").value)
  end

  it "sql_case_insensitive" do
    OracleSpec.check("sql_case_insensitive", HL.highlight("SELECT NAME FROM USERS WHERE ID = 1;", "sql").value)
  end
end
