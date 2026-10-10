def render
  text = <<~HTML
    <div class="x">#{name}</div>
  HTML
  other = <<~'RAW'
    no #{interp}
  RAW
end
