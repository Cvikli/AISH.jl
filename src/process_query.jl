
streaming_process_question(ai_state::AIState, user_question, shell_results=OrderedDict{String, CodeBlock}(); 
    on_meta_usr=noop,  
    on_text=noop,  
    on_meta_ai=noop,
    on_error=nothing, on_done=nothing, on_start=nothing) = begin
    try
        question = prepare_user_message!(ai_state.contexter, ai_state, user_question, shell_results)
        add_n_save_user_message!(ai_state, question)
        ai_message, shell_scripts = process_message(ai_state; on_meta_usr,  on_text,  on_meta_ai, on_error, on_done, on_start)
        return ai_message, shell_scripts, nothing
    catch e
        @error "Error executing code block: $(sprint(showerror, e))" exception=(e, catch_backtrace())
        return nothing, nothing, e
    end
end


function process_message(state::AIState; on_meta_usr=noop, on_text=noop, on_meta_ai=noop, on_error=nothing, on_done=nothing, on_start=nothing)
    extractor = ShellScriptExtractor()
    clearline()
    stop_spinner = progressing_spinner()

    cache   = get_cache_setting(state.contexter, curr_conv(state))
    channel = ai_stream_safe(state, printout=false, cache=cache)
    
    stream_kwargs = Dict{Symbol, Any}()
    stream_kwargs[:on_meta_usr] = onmetauser(meta) = begin
            stop_spinner[] = true
            clearline()
            println("\e[32mUser message: \e[0m$(format_meta_info(meta))")
            on_meta_usr(update_last_user_message_meta(state, meta))
            print("\e[36m¬ \e[0m")
        end
    stream_kwargs[:on_text] = ontext(text) = begin
            on_text(text, extract_and_preprocess_shell_scripts(text, extractor))
            print(text)
        end
    stream_kwargs[:on_meta_ai] = onmetaai(meta, full_msg) = begin
            on_meta_ai(add_n_save_ai_message!(state, full_msg, meta))
            println("\n\e[32mAI message: \e[0m$(format_meta_info(meta))")
        end
    stream_kwargs[:on_error] = (error) -> begin
        error_content = "\nERROR: $error"
        stop_spinner[] = true
        if curr_conv_msgs(state)[end].role == :user 
            add_n_save_ai_message!(state, error_content)
        elseif curr_conv_msgs(state)[end].role == :assistant 
            update_message_by_id(state, curr_conv_msgs(state)[end].id, curr_conv_msgs(state)[end].content * error_content)
        end
        on_error !== nothing && on_error(error)
    end
    stream_kwargs[:on_done]  = () -> begin
        
        on_done !== nothing && on_done()
    end
    on_start !== nothing && (stream_kwargs[:on_start] = on_start)

    process_stream(channel; stream_kwargs...)

    shell_scripts = !state.skip_code_execution ? execute_shell_commands(extractor; no_confirm=state.no_confirm) : OrderedDict{String, CodeBlock}()

    return curr_conv_msgs(state)[end], shell_scripts
end

process_message_nostream() = begin
    assistant_message = anthropic_ask_safe(state, cache=cache)
    stop_spinner[] = true
    clearline()
    msg = assistant_message.content
    ai_meta = StreamMeta(input_tokens=assistant_message.tokens[1], output_tokens=assistant_message.tokens[2], price=assistant_message.cost, elapsed=assistant_message.elapsed)
    println("\e[36m¬ \e[0m$(msg)")
    
    # Extract shell commands for non-streaming case
    extract_and_preprocess_shell_scripts(msg, extractor)
end



