

include("../src/benchmarking/benchmark_event_scheduler.jl")


#%%

include("../src/benchmarking/benchmark_event_scheduler.jl")

benchmark_event_scheduler()
save_benchmark_result()


#%%
BENCHMARK_RESULTS
#%%


using PrettyPrinting
passed, all_passed = 0, 0
exec, all_exec = 0, 0
for (promptlabel,res) in BENCHMARK_RESULTS
	print_score(res)
	passed += res["unit_tests_passed"]
	all_passed += res["unit_tests_count"]
	exec += res["examples_executed"]
	all_exec += res["examples_count"]
end

format_percentage(x::Float64) = string(round(x * 100, digits=2), "%")

println("Pass: $(format_percentage(passed/all_passed)),  Exec: $(format_percentage(exec/all_exec))")




#%%
include("../src/benchmarking/benchmark_event_scheduler.jl")
save_benchmark_result()
#%%
pwd()
#%%
# Pass: 69.12%,  Exec: 77.55%

#%%









