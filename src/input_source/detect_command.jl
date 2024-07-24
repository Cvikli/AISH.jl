is_command(words) = findfirst(w -> strip(w, [',', ' ']) == ainame, words)

detect_vex_command(msg) = begin
  words = split(lowercase(msg))
  vex_index = is_command(words)
  return isnothing(vex_index) ? "" : join(words[vex_index+1:end], " ")
end