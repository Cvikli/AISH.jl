println("enter integer i <CR> decimal d <CR> string s <CR>")
i=""
i *= readline();
d = readline();
s = readline();
println("done")
@show (i,d,s)

#%%
# Redirect stdin to this buffer
name = readline(IOBuffer("\n"))
println("Hello, $name")
name2  = readline(stdin)
name26 = readline()
println("Hello, $name2")
println("Hello, $name26")
println("WORKED???")

#%%

println("10\r9")