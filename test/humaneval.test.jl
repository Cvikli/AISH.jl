using RelevanceStacktrace
using HumanEval
using AISH
using Test
using ReTestItems

ENV["GENERATION_DIR"] = "test/humaneval"

function solve_and_test_humaneval(task::HumanEval.HumanEvalTask)
    solution_file = joinpath(ENV["GENERATION_DIR"], "$(task.task_id)_$(task.entrypoint).jl")
    message = """
    Solve this Julia programming problem and save it to the $(solution_file) file. Provide only the function implementation, without explanation:\
    
    $(task.prompt)
    """
    @show "ok"
    println(task.prompt)
    @show "hey"
    println("using ReTestItems\n\n$(task.basic_test_cases)")
    AISH.start(message, loop=true, no_confirm=true, test_cases="using ReTestItems\n\n$(task.basic_test_cases)")
    
    !isfile(solution_file) && return false, "Solution file not generated", ""
    
    solution_code = read(solution_file, String)
    
    try
        Base.eval(Main, Meta.parse("begin $(task.basic_test_cases) end"))
        true, "All tests passed", solution_code
    catch e
        if e isa InterruptException
            println("\nInterrupted during testing. Exiting...")
            exit(0)
        end
        false, sprint(showerror, e), solution_code
    end
end

mkpath(joinpath("test", "humaneval"))
till = "026"
done = String[]
for task in HumanEval.get_tasks()
    push!(done, task.task_id)
    !(till in done) && continue
    
    println("\nTesting problem $(task.task_id):")
    success, result, solution = solve_and_test_humaneval(task)
    # println("Solution:\n$solution")
    println("\nResult: ", success ? "✅ $result" : "❌ $result")
end

    
