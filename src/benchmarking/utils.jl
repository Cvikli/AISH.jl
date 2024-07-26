using Dates
using Printf
using TOML
using DataStructures: OrderedDict

function extract_sh_block_to_julia_code(input_string)
    @show "input_string"
    println(input_string)
    code_block_regex = r"```sh\n(.*?)```\n"s
    m = match(code_block_regex, input_string)
    m === nothing && return input_string

    code_content = m.captures[1]
    julia_code = replace(code_content, r".*?\"EOL\"\n"s => "")
    julia_code = replace(julia_code, r"\nEOL.*"s => "")

    return replace(input_string, code_block_regex => "```julia\n$julia_code\n```")
end

print_score(res) = begin
    if res isa Dict
        println("Parsed: $(res["parsed"]) Executed: $(res["executed"]), P: $(res["unit_tests_passed"])/$(res["unit_tests_count"]), E: $(res["examples_executed"])/$(res["examples_count"]), $(res["elapsed_seconds"])s, \$$(res["cost"]) Label: $(res["prompt_label"])")
    else
        println("Parsed: $(res.parsed) Executed: $(res.executed), P: $(res.unit_tests_passed)/$(res.unit_tests_count), E: $(res.examples_executed)/$(res.examples_count), $(res.elapsed_seconds)s, \$$(res.cost) Label: $(res.prompt_label)")
    end
end

function save_benchmark_result(benchmark_results::OrderedDict{String, Dict{String, Any}} = BENCHMARK_RESULTS)
    date_str = Dates.format(Dates.now(), "yyyy-mm-dd_HH-MM-SS")
    
    # Get the current git commit hash
    git_commit = try
        readchomp(`git rev-parse --short HEAD`)
    catch
        "Unknown"
    end
    
    filename = "benchmark_results_$(date_str)_$(git_commit).toml"
    
    # Calculate overall pass and exec percentages
    total_passed = sum(res["unit_tests_passed"] for (_, res) in benchmark_results)
    total_all_passed = sum(res["unit_tests_count"] for (_, res) in benchmark_results)
    total_exec = sum(res["examples_executed"] for (_, res) in benchmark_results)
    total_all_exec = sum(res["examples_count"] for (_, res) in benchmark_results)
    
    pass_percentage = @sprintf("%.2f", (total_passed / total_all_passed) * 100)
    exec_percentage = @sprintf("%.2f", (total_exec / total_all_exec) * 100)
    
    # Create the content to be written to the file
    result = OrderedDict(
        "metadata" => Dict(
            "date" => date_str,
            "git_commit" => git_commit,
            "overall_pass" => "$pass_percentage%",
            "overall_exec" => "$exec_percentage%"
        ),
        "prompt_results" => benchmark_results
    )
    
    # Write the content to the file in TOML format
    open("benchmarks/" * filename, "w") do file
        TOML.print(file, result)
    end
    
    println("Benchmark results saved to $filename")
    return filename
end


function compare_benchmark_results(file1::String, file2::String)
    result1 = TOML.parsefile(file1)
    result2 = TOML.parsefile(file2)
    
    println("Comparing benchmark results:")
    println("File 1: $(result1["metadata"]["date"]) ($(result1["metadata"]["git_commit"]))")
    println("File 2: $(result2["metadata"]["date"]) ($(result2["metadata"]["git_commit"]))")
    println()
    
    println("Overall results:")
    println("Pass: $(result1["metadata"]["overall_pass"]) vs $(result2["metadata"]["overall_pass"])")
    println("Exec: $(result1["metadata"]["overall_exec"]) vs $(result2["metadata"]["overall_exec"])")
    println()
    
    println("Prompt-level comparisons:")
    for prompt_label in keys(result1["prompt_results"])
        if haskey(result2["prompt_results"], prompt_label)
            println("  $prompt_label:")
            r1 = result1["prompt_results"][prompt_label]
            r2 = result2["prompt_results"][prompt_label]
            println("    Parsed: $(r1["parsed"]) vs $(r2["parsed"])")
            println("    Executed: $(r1["executed"]) vs $(r2["executed"])")
            println("    Unit tests: $(r1["unit_tests_passed"])/$(r1["unit_tests_count"]) vs $(r2["unit_tests_passed"])/$(r2["unit_tests_count"])")
            println("    Examples: $(r1["examples_executed"])/$(r1["examples_count"]) vs $(r2["examples_executed"])/$(r2["examples_count"])")
            println("    Time: $(r1["elapsed_seconds"])s vs $(r2["elapsed_seconds"])s")
            println("    Cost: \$$(r1["cost"]) vs \$$(r2["cost"])")
        else
            println("  $prompt_label: Only present in file 1")
        end
    end
    
    for prompt_label in keys(result2["prompt_results"])
        if !haskey(result1["prompt_results"], prompt_label)
            println("  $prompt_label: Only present in file 2")
        end
    end
end
