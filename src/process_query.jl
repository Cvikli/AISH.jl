
streaming_process_question(ai_state::AIState, user_question, shell_results=Dict{String, String}()) = begin
    question = prepare_user_message!(ai_state.contexter, ai_state, user_question, shell_results)
    user_msg = add_n_save_user_message!(ai_state, question)
    cache = get_cache_setting(ai_state.contexter, curr_conv(ai_state))
    full_response, user_meta, ai_meta, start_time = ai_stream_safe(ai_state, printout=false, cache=cache)
    full_response, user_meta, ai_meta, start_time, user_msg
end

process_question(ai_state::AIState, user_question::String, shell_results=Dict{String, String}()) = begin
    question = prepare_user_message!(ai_state.contexter, ai_state, user_question, shell_results)
    add_n_save_user_message!(ai_state, question)
    process_message(ai_state)
end

function process_message(state::AIState)
    local ai_meta, msg

    if state.streaming
        print("\n\e[32m¬ \e[0m")
        cache = get_cache_setting(state.contexter, curr_conv(state))
        full_response, user_meta, ai_meta, start_time = ai_stream_safe(state, printout=false, cache=cache) 
        msg = channel_to_string(full_response, cb=on_start_callback(user_meta, start_time))
        calc_elapsed_times(ai_meta, user_meta.elapsed, start_time)
        update_last_user_message_meta(state, user_meta)
        println("")
    else
        println("Thinking...")
        cache = get_cache_setting(state.contexter, curr_conv(state))
        assistant_message = anthropic_ask_safe(state, cache=cache)
        msg = assistant_message.content
        ai_meta = StreamMeta(input_tokens=assistant_message.tokens[1], output_tokens=assistant_message.tokens[2], price=assistant_message.cost, elapsed=assistant_message.elapsed)
        println("\n\e[32m¬ \e[0m$(msg)")
    end

    shell_scripts = extract_shell_commands(msg)

    if !state.skip_code_execution
      shell_scripts = execute_shell_commands(shell_scripts)
    end

    add_n_save_ai_message!(state, msg, ai_meta)

    println("\e[32mAI message meta: \e[0m$(format_meta_info(ai_meta))")

    return curr_conv_msgs(state)[end], shell_scripts
end

function on_start_callback(user_meta, start_time)
    on_start = () -> begin
        user_meta.elapsed -= start_time
        println("\e[34mUser message meta: \e[0m$(format_meta_info(user_meta))")
    end
    return on_start
end

function get_shortened_code(code::String, max_lines::Int=3)
    lines = split(code, '\n')
    if length(lines) > max_lines
        return join(lines[1:2], '\n') * "\n...\n" * lines[end]
    else
        return code
    end
end
