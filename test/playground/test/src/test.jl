file_path="test/playground/test/src/profile_startup.jl"
lines=readlines(file_path, keep=true)
@show lines
show(join(lines, "\n"))
println()
show(read(file_path,String) )
println()
@assert join(lines, "\n") == read(file_path,String) 



#%%
x="1\n2\n3\n\n\n\n\n"
for i in 1:5
	lines=readlines(IOBuffer(x))
	x=join( lines, "\n") * '\n'
	show(x)
	println()
end
#%%
println("------")
k_=readlines(IOBuffer("1\n2\n3"))
foreach(println, k_)
println("------")

#%%

readlines(IOBuffer("1\n2\n3\n"), keep=false)
#%%

readlines(IOBuffer("1\n2\n3\n"), keep=true)
readlines(IOBuffer("""1
2
3
"""), keep=true)
readlines(IOBuffer("""1
2
3"""), keep=true)