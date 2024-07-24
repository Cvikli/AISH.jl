include("file_diff_tracker.jl")

function process_question(state::AIState)
    println("Thinking...")

    assistant_message = aigenerate(state.conversation, model=state.model)
    push!(state.conversation, assistant_message)
    println("\e[32m\$\e[0m $(assistant_message.content)")  # Green $ symbol
    println()

    code_blocks = extract_all_code(assistant_message.content)
    all_outputs = String[]
    changed = false

    for (index, code) in enumerate(code_blocks)
        changed |= process_code_block!(index, code, all_outputs)
    end

    state.last_output = all_outputs
    display_final_outputs(state.last_output)

    changed && update_system_prompt!(state)
end

function process_code_block!(index, code, all_outputs)
    !startswith(code, "cat > ") && return false

    println("\e[34mCode block $index:\e[0m")
    println("\e[2m$code\e[0m")
    
    file_diff = generate_file_diff(String(code))  # Convert SubString to String
    isnothing(file_diff) && return false

    display_file_diff(file_diff)
    
    return true
end

function execute_code_block(code, all_outputs)
    try
        output = strip(read(`bash -c $code`, String))
        push!(all_outputs, output)
    catch error
        error_output = strip(sprint(showerror, error))
        push!(all_outputs, "[Error]\n$error_output")
        @warn("Error occurred during execution: $error_output")
    end
    println("\e[35mCurrent output:\e[0m\n$(all_outputs[end])")
end

function display_final_outputs(outputs)
    println("\n\e[35mFinal Outputs:\e[0m")
    for (index, output) in enumerate(outputs)
        println("Output $index:\n$output\n")
    end
end

extract_all_code(text) = [String(strip(m.captures[1])) for m in eachmatch(r"```sh\n([\s\S]*?)\n```", text)]
