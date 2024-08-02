using Statistics

function weather_data_analyzer(temps::Vector{<:Real})
    if isempty(temps)
        return (; average=nothing, max=nothing, min=nothing, trend=nothing)
    end

    avg = mean(temps)
    max_temp = maximum(temps)
    min_temp = minimum(temps)

    # Calculate the trend
    if length(temps) > 1
        first_half = temps[1:div(end, 2)]
        second_half = temps[div(end, 2)+1:end]
        
        first_half_mean = mean(first_half)
        second_half_mean = mean(second_half)
        
        if isapprox(first_half_mean, second_half_mean, atol=0.1)
            trend = :stable
        elseif second_half_mean > first_half_mean
            trend = :increasing
        else
            trend = :decreasing
        end
    else
        trend = :stable
    end

    return (; average=avg, max=max_temp, min=min_temp, trend=trend)
end
#%%
```

This function...

```julia
#%%
temps = [20.5, 21.0, 22.5, 23.0, 22.0, 21.5, 23.5]
result = weather_data_analyzer(temps)
println(result)
#%%
```

This will output something like:
```
(average = 22.0, max = 23.5, min = 20.5, trend = :increasing)
```

And for an empty list:

```julia
#%%

empty_temps = Float64[]
empty_result = weather_data_analyzer(empty_temps)
println(empty_result)
#%%
```

This will output:
```
(average = nothing, max = nothing, min = nothing, trend = nothing)

#%%

try
cmd = """
read -q "?continue? (y) " && cat > README_FINAL.md <<-"EOL"
content
EOL
"""
run(`zsh -c $cmd`)
catch error
    @show error
    @show error.procs
    @show error.procs[1].exitcode
    ProcessFailedException
    error_output = strip(sprint(showerror, error))
    @warn("Error occurred during execution: $error_output")
  end

#%%
using REPL
using REPL.LineEdit
xx=IOBuffer()
# isempty(take!(xx))
position(xx)
input = String(xx)


#%!

using REPL
using REPL.LineEdit

function readline_improved()
    # Set up a prompt string
    prompt_str = "➜ "

    # Create a custom keymap
    keymap = Dict{Any,Any}(
        '\r' => function (s,o...)
            if position(LineEdit.buffer(s)) == 0
                return :done
            end
            return :done
        end,
        Char(4) => function (s,o...)
            if position(LineEdit.buffer(s))  > 0
                LineEdit.edit_insert(s, "")
                return nothing
            else
                return :done
            end
        end
    )

    # Create a custom on_done function
    function on_done(s, buf, ok)
        if !ok
            return :abort
        end
        return String(buf)
    end

    # Create a custom REPL mode
    mode = LineEdit.Prompt(
        prompt_str,
        prompt_prefix = "\e[36m",
        prompt_suffix = "\e[0m",
        keymap_dict = keymap,
        on_done = on_done
    )

    # Set up the terminal
    if isdefined(Base, :active_repl)
        repl = Base.active_repl
        terminal = repl.t
    else
        terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
    end

    # Create a ModalInterface with our single mode
    mi = ModalInterface([mode])

    s = LineEdit.init_state(terminal, mi)
    LineEdit.edit_insert(s, "")  # Ensure the buffer is initialized
    LineEdit.prompt!(terminal, mi, s)

    # Get the input from the buffer
    input = String(take!(LineEdit.buffer(s)))
    @show input

    # Return the input as a string
    return strip(input)
end

#%%

a= """
ys try to use the sh blocks that was told to you to solve the tasks! \n\nWith these informations in mind you can communicate with the user from here!\nUser requests arrive these are what you have to fulfill.\n\n===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===\n2024-08-02T13:38:58.410 [user]: are the any chance that randomly I save the systemprompt again?\n===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===\n2024-08-02T13:39:47.852 [ai]: To investigate whether there's a chance of randomly saving the system prompt again, let's review the relevant code. We'll focus on the functions related to saving messages and updating the system prompt.\n\nFirst, let's look at the `save_message` function in the `src/messages.jl` file:\n\n```sh\nmeld src/messages.jl <(cat <<-\"EOL\"\nfunction save_message(state::AIState, role, message)\n    mkpath(CONVERSATION_DIR)\n    conversation_id = state.selected_conv_id\n    message_separator = get_message_separator(conversation_id)\n    existing_file = get_conversation_filename(conversation_id)\n\n    if isnothing(existing_file)\n        first_user_message = cur_conv(state)[2]\n        sanitized_chars = strip(replace(replace(first(first_user_message.content, 32), r\"[^\\w\\s-]\" => \"_\"), r\"\\s+\" => \"_\"), '_')\n        state.conversation_sentences[conversation_id] = sanitized_chars\n        filename = joinpath(CONVERSATION_DIR, \"\$(Dates.format(first_user_message.timestamp, \"yyyy-mm-dd_HH:MM:SS\"))_\$(sanitized_chars)_\$(conversation_id).log\")\n    else\n        filename = existing_file\n    end\n    if length(cur_conv(state)) >= 2\n        open(filename, isnothing(existing_file) ? \"w\" : \"a\") do file\n            if isnothing(existing_file) || length(cur_conv(state)) == 2\n                for msg in cur_conv(state)\n                    println(file, \"\$(msg.timestamp) [\$(msg.role)]: \$(msg.content)\")\n                    println(file, message_separator)\n                end\n            else\n                println(file, \"\$(now()) [\$(role)]: \$(message)\")\n                println(file, message_separator)\n            end\n        end\n    end\nend\nEOL\n)\n```\n```sh_run_results\n(stdout = \"\", stderr = \"\", exit_code = 0, exception = nothing)\n```\n\n\nNow, let's examine the `update_system_prompt!` function in the `src/AI_struct.jl` file:\n\n```sh\nmeld src/AI_struct.jl <(cat <<-\"EOL\"\n# Update system prompt\nfunction update_system_prompt!(state::AIState)\n    new_system_prompt = SYSTEM_PROMPT()\n    cur_conv(state)[1] = Message(now(), :system, new_system_prompt)\n    println(\"\\e[33mSystem prompt updated due to file changes.\\e[0m\")\nend\nEOL\n)\n```\n```sh_run_results\n(stdout = \"\", stderr = \"\", exit_code = 0, exception = nothing)\n```\n\n\nBased on this code, we can conclude:\n\n1. The system prompt is not directly saved using the `save_message` function. It's only updated in memory within the `update_system_prompt!` function.\n\n2. The `save_message` function is designed to save messages to a file, but it has a condition `if length(cur_conv(state)) >= 2` before writing anything. This means it won't save anything if there's only one message (which would be the system prompt) in the conversation.\n\n3. When saving messages, it checks if the file is new (`isnothing(existing_file)`) or if it's the second message in the conversation (`length(cur_conv(state)) == 2`). In these cases, it writes all messages, including the system prompt. Otherwise, it only appends the new message.\n\n4. The `update_system_prompt!` function is called in the `process_question` function in `src/process_query.jl`, which happens after processing each user query.\n\nGiven this implementation, there are a few scenarios where the system prompt might be saved again:\n\n1. When starting a new conversation (creating a new file).\n2. When the second message in a conversation is being saved.\n3. If the system prompt is updated due to file changes, and then a new user message triggers the saving process.\n\nHowever, this is not random. It happens in specific, deterministic situations. The system prompt won't be randomly saved again during normal conversation flow after the initial save.\n\nTo prevent unnecessary repeated saves of the system prompt, you could modify the `save_message` function to only save non-system messages after the initial save. If you want to implement this change, let me know, and I can provide the modified code.\n===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===\n"
"""
strip.(split(a, "===AISH_MSG_734b7fee-074c-480e-8c10-5264c314f9ce===", keepempty=false))

#%%


get_id_from_file(filename) = (m = match(r"^\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(?<id>.+)_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.log$", filename); return m !== nothing ? m[:id] : "")


get_id_from_file("2024-08-02_13:38:58_are_the_any_chance_that_randomly_734b7fee-074c-480e-8c10-5264c314f9ce.log")
