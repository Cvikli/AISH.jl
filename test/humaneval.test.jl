using RelevanceStacktrace
using HumanEval
using AISH
using Test
using ReTestItems  # Add this line

ENV["GENERATION_DIR"] = "test/humaneval"
function solve_and_test_humaneval(problem_id::String)
    tasks = HumanEval.get_tasks()
    task_i = findfirst(t -> t.task_id == problem_id, tasks)
    
    if task_i === nothing
        throw(ArgumentError("Invalid problem ID: $problem_id"))
    end
    task = tasks[task_i]
    prompt = task.prompt
    
    solution_file = joinpath(ENV["GENERATION_DIR"], "$(problem_id)_$(task.entrypoint).jl")
    # Use AISH to generate a solution and save it to a file
    message = """
    Solve this Julia programming problem and save it to the $(solution_file) file. Provide only the function implementation, without explanation:

    $prompt
    """
    
    AISH.start(message, loop=false)
    # Read the generated solution
    if !isfile(solution_file)
        return false, "Solution file not generated", ""
    end
    
    solution_code = read(solution_file, String)
    
    # Create a test module
    test_module = Module()
    
    # Define the function and run tests in the test module
    test_code = """
    $(solution_code)
    
    using Test
    using ReTestItems
    $(task.basic_test_cases)
    """
    @show test_code
    try
        Core.eval(test_module, Meta.parse(test_code))
        return true, "All tests passed", solution_code
    catch e
        return false, sprint(showerror, e), solution_code
    end
end

# Ensure the output directory exists
mkpath(joinpath("test", "humaneval"))

# Run tests for a few problems
for problem_id in ["000", "001", "002", "010"]
    println("\nTesting problem $problem_id:")
    success, result, solution = solve_and_test_humaneval(problem_id)
    println("Solution:")
    println(solution)
    println("\nResult: ", success ? "✅ $result" : "❌ $result")
end


#%%
#%%
ENV["GENERATION_DIR"] = "test/humaneval"
ENV["GENERATION_DIR"]
#%%
using HumanEval
@show fieldnames(typeof(HumanEval.get_tasks()[2]))
println(HumanEval.get_tasks()[2].basic_test_cases)
println(HumanEval.get_tasks()[2].entrypoint)