require "../src/highlight"
def unesc(v)
  v.gsub("\\\\", "\u{0}").gsub("\\n", "\n").gsub("\\t", "\t").gsub("\\r", "\r").gsub("\u{0}", "\\")
end
exp = {} of String => String
File.read_lines("oracle/expected.yml").each { |l| k, _, v = l.partition('\t'); exp[k] = v }
lang = ARGV[0]
snippet = ARGV[1]
code = File.read("oracle/snippets/#{snippet}")
actual = unesc(Highlight.highlight(code, lang).value)
expected = unesc(exp["#{lang}_html"])
# первое расхождение
n = Math.min(actual.size, expected.size)
i = 0
while i < n && actual[i] == expected[i]
  i += 1
end
puts "first diff at #{i} (exp.size=#{expected.size} act.size=#{actual.size}):"
puts "  exp[#{i},40]: #{expected[i, 40].inspect}"
puts "  act[#{i},40]: #{actual[i, 40].inspect}"
