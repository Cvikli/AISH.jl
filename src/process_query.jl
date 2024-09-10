streaming_process_question(ai_state::AIState, user_question, shell_results=Dict{String, String}()) = begin
    user_msg = nothing
    try
        question = prepare_user_message!(ai_state.contexter, ai_state, user_question, shell_results)
        user_msg = add_n_save_user_message!(ai_state, question)
        cache = get_cache_setting(ai_state.contexter, curr_conv(ai_state))
        channel = ai_stream_safe(ai_state, printout=false, cache=cache)
        return channel, user_msg, nothing
    catch e
        @error "Error executing code block: $(sprint(showerror, e))" exception=(e, catch_backtrace())
        return nothing, user_msg, e
    end
end

process_question(ai_state::AIState, user_question::String, shell_results=Dict{String, String}()) = begin
    try
        question = prepare_user_message!(ai_state.contexter, ai_state, user_question, shell_results)
        add_n_save_user_message!(ai_state, question)
        ai_message, shell_scripts = process_message(ai_state)
        return ai_message, shell_scripts, nothing
    catch e
        @error "Error executing code block: $(sprint(showerror, e))" exception=(e, catch_backtrace())
        return nothing, nothing, e
    end
end

function process_message(state::AIState)
    local ai_meta, msg

    if state.streaming
        cache = get_cache_setting(state.contexter, curr_conv(state))
        channel = ai_stream_safe(state, printout=false, cache=cache) 
        print("\e[36m¬ \e[0m")
        msg, user_meta, ai_meta = process_stream(channel, state.model, 
            on_text=print, 
            on_meta_usr=meta->(println("\e[32mUser message: \e[0m$(format_meta_info(meta))"); update_last_user_message_meta(state, meta)), 
            on_meta_ai=meta->println("\e[32mAI message: \e[0m$(format_meta_info(meta))"))
        
        println("")
    else
        println("Thinking...")
        cache = get_cache_setting(state.contexter, curr_conv(state))
        assistant_message = anthropic_ask_safe(state, cache=cache)
        msg = assistant_message.content
        ai_meta = StreamMeta(input_tokens=assistant_message.tokens[1], output_tokens=assistant_message.tokens[2], price=assistant_message.cost, elapsed=assistant_message.elapsed)
        println("\e[36m¬ \e[0m$(msg)")
    end

    add_n_save_ai_message!(state, msg, ai_meta)

    

# TODO move this to somewhere else... this doesn't have to be in this function!
    shell_scripts = extract_shell_commands(msg)
    if !state.skip_code_execution
        shell_scripts = execute_shell_commands(shell_scripts)
    end



    return curr_conv_msgs(state)[end], shell_scripts
end

function on_start_callback(user_meta, start_time)
    on_start = () -> begin
        user_meta.elapsed -= start_time
        println("\e[34mUser message meta: \e[0m$(format_meta_info(user_meta))")
    end
    return on_start
end

function get_shortened_code(code::String, head_lines::Int=4, tail_lines::Int=3)
    lines = split(code, '\n')
    total_lines = length(lines)
    
    if total_lines <= head_lines + tail_lines
        return code
    else
        head = join(lines[1:head_lines], '\n')
        tail = join(lines[end-tail_lines+1:end], '\n')
        return "$head\n...\n$tail"
    end
end

function execute_shell_command_async(command::String, channel::Channel)
    try
        cmd = Cmd(split(command))
        process = open(cmd, "r")
        for line in eachline(process)
            put!(channel, line)
        end
        close(process)
    catch e
        put!(channel, "Error: $(sprint(showerror, e))")
    end
end

function select_folder_async(path::String, channel::Channel)
    try
        for (root, dirs, files) in walkdir(path)
            for dir in dirs
                put!(channel, joinpath(root, dir))
            end
            for file in files
                put!(channel, joinpath(root, file))
            end
        end
    catch e
        put!(channel, "Error: $(sprint(showerror, e))")
    end
end

function modify_file_async(file_path::String, modifications::String, channel::Channel)
    try
        # Implement file modification logic here
        # Use `put!(channel, update)` to send progress updates
        # This is a placeholder implementation
        put!(channel, "Starting file modification")
        # ... perform actual file modifications ...
        put!(channel, "File modification completed")
    catch e
        put!(channel, "Error: $(sprint(showerror, e))")
    end
end
