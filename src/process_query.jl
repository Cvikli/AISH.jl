streaming_process_query(ai_state::AIState, user_message) = begin
  add_n_save_user_message!(ai_state, user_message)
  full_response, user_meta, ai_meta, start_time = ai_stream_safe(ai_state, printout=false)
  # append_token_information()
  full_response, user_meta, ai_meta, start_time
end

process_query(ai_state::AIState, user_message) = begin
  add_n_save_user_message!(ai_state, user_message)
  process_question(ai_state)
end

function process_question(state::AIState)
  local ai_msg
  update_system_prompt!(state)

  if state.streaming
    print("\e[32m¬ \e[0m")
    full_response, user_meta, ai_meta, start_time = ai_stream_safe(state, printout=false) 
    msg = channel_to_string(full_response)
    calc_elapsed_times(user_meta, ai_meta, start_time)
    # append_token_information(state, user_meta)
    updated_content = state.skip_code_execution ? msg : update_message_with_outputs(msg)
    ai_msg = Message(timestamp=now(), role=:assistant, content=updated_content, id="", itok=ai_meta.input_tokens, otok=ai_meta.output_tokens, price=ai_meta.price, elapsed=ai_meta.elapsed)
  else
    println("Thinking...")  
    assistant_message = anthropic_ask_safe(state)
    msg = assistant_message.content
    updated_content = state.skip_code_execution ? msg : update_message_with_outputs(msg)
    user_meta = StreamMeta()
    ai_msg = Message(timestamp=now(), role=:assistant, content=updated_content, id="", itok=assistant_message.tokens[1], otok=assistant_message.tokens[2], price=assistant_message.cost, elapsed=assistant_message.elapsed)
  end
  println("\n\e[32m¬ \e[0m$(updated_content)")

  add_n_save_ai_message!(state, ai_msg)

  return cur_conv_msgs(state)[end]
end


update_message_with_outputs(content) = return replace(content, r"```sh\n([\s\S]*?)\n```" => matchedtxt -> begin
  code = matchedtxt[7:end-3]
  output = execute_code_block(code)
  "$matchedtxt\n```sh_run_results\n$output\n```\n"
end)

execute_code_block(code) = withenv("GTK_PATH" => "") do
  println("\e[32m$(code)\e[0m")
  return if startswith(code, "meld") 
    cmd_all_info(`zsh -c $code`) 
  else
    print("\e[34mContinue? (y) \e[0m")
    readchomp(`zsh -c "read -q '?'; echo \$?"`) == "0" ? cmd_all_info(`zsh -c $code`) : "Operation cancelled by user."
  end
end


function cmd_all_info(cmd::Cmd, output=IOBuffer(), error=IOBuffer())
  err, process = "", nothing
  try
    process = run(pipeline(ignorestatus(cmd), stdout=output, stderr=error))
  catch e
    err = "$e"
  end
  join(["$name=$str" for (name, str) in [("stdout", String(take!(output))), ("stderr", String(take!(error))), ("exception", err), ("exit_code", isnothing(process) ? "" : process.exitcode)] if !isempty(str)], "\n")
end
