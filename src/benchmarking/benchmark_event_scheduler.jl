using AISH: initialize_ai_state
using JuliaLLMLeaderboard
using RelevanceStacktrace
using PromptingTools
using TOML

using JuliaLLMLeaderboard: find_definitions

include("generic_benchmark.jl")

# Global variable to store benchmark results
BENCHMARK_RESULTS::Dict{String, Dict{String, Any}} = Dict{String, Dict{String, Any}}()

function benchmark_event_scheduler()
    println("Benchmark started...")
    fn_definitions = find_definitions(joinpath(dirname(dirname(pathof(JuliaLLMLeaderboard))),"code_generation/"))

    for fn_definition in fn_definitions
        definition = TOML.parsefile(fn_definition)["code_generation"]
        name = definition["name"]

        if haskey(BENCHMARK_RESULTS, name) &&
           BENCHMARK_RESULTS[name]["examples_executed"] == BENCHMARK_RESULTS[name]["examples_count"] &&
           BENCHMARK_RESULTS[name]["unit_tests_passed"] == BENCHMARK_RESULTS[name]["unit_tests_count"]
            println("Skipping $name - All tests already passed.")
        else
            result = run_generic_benchmark(fn_definition)
            BENCHMARK_RESULTS[name] = Dict(
                "examples_executed" => result.examples_executed,
                "examples_count" => result.examples_count,
                "unit_tests_passed" => result.unit_tests_passed,
                "unit_tests_count" => result.unit_tests_count,
                "parsed" => result.parsed,
                "executed" => result.executed,
                "elapsed_seconds" => result.elapsed_seconds,
                "cost" => result.cost,
                "prompt_label" => result.prompt_label
            )
        end
    end

    return BENCHMARK_RESULTS
end
