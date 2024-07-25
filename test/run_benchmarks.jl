

include("../src/benchmarking/benchmark_event_scheduler.jl")


ress = benchmark_event_scheduler()


#%%
#%%
using PrettyPrinting
passed, all_passed = 0, 0
exec, all_exec = 0, 0
for res in ress
	print_score(res)
	passed += res.unit_tests_passed
	all_passed += res.unit_tests_count
	exec += res.examples_executed
	all_exec += res.examples_count
end

format_percentage(x::Float64) = string(round(x * 100, digits=2), "%")

println("Pass: $(format_percentage(passed/all_passed)),  Exec: $(format_percentage(exec/all_exec))")

#%%

ress2 = ress
#%%
typeof(res)
#%%
#%%
include("../src/benchmarking/benchmark_event_scheduler.jl")
using Revise
test_str = """
```sh
read -q "?continue? (y) " && cat > markdown_utils.jl <<-"EOL"
function extract_julia_code(md::String)
    code_blocks = match.(r"```julia\n(.*?)\n```"s, md)
    valid_blocks = filter(x -> x !== nothing, code_blocks)
    extracted_code = map(m -> m.captures[1], valid_blocks)
    return join(extracted_code, "\n")
end
EOL
```
"""

extract_sh_block_to_julia_code(test_str)
