file_path="test/playground/test/src/profile_startup.jl"
lines=readlines(file_path, keep=true)
@show lines
show(join(lines, "\n"))
println()
show(read(file_path,String) )
println()
@assert join(lines, "\n") == read(file_path,String) 