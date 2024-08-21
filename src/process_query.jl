
create_conversation(ai_state, question) = begin
  conv = curr_conv(ai_state)
  codebase_ctx = get_codebase_ctx(question, conv.rel_project_paths)
  sysprompt = SYSTEM_PROMPT(ctx=codebase_ctx)
  msgs_history = get_history(conv, keep=5)
  context_msg = get_context_msg(question)
  new_user_msg = get_new_user_msg(question)
  [sysprompt, msgs_history..., context_msg, new_user_msg]
end


streaming_process_question(ai_state::AIState, user_message) = begin
  add_n_save_user_message!(ai_state, user_message)
  full_response, user_meta, ai_meta, start_time = ai_stream_safe(ai_state, printout=false)
  # append_token_information()
  full_response, user_meta, ai_meta, start_time
end
process_question(ai_state::AIState, user_question) = begin
  # conv = create_conversation(ai_state, question)

  add_n_save_user_message!(ai_state, user_question)
  process_message(ai_state)
end

function process_message(state::AIState)
  local ai_meta, msg
  update_project_path_and_sysprompt!(state)

  if state.streaming
    full_response, user_meta, ai_meta, start_time = ai_stream_safe(state, printout=false) 
    msg = channel_to_string(full_response, cb=() -> (user_meta.elapsed -= start_time; println("\e[34mUser message meta: \e[0m$(format_meta_info(user_meta))")))
    calc_elapsed_times(ai_meta, user_meta.elapsed, start_time)
    update_last_user_message_meta(state, user_meta)
  else
    println("Thinking...")  
    assistant_message = anthropic_ask_safe(state)
    msg = assistant_message.content
    ai_meta = StreamMeta(input_tokens=assistant_message.tokens[1], output_tokens=assistant_message.tokens[2], price=assistant_message.cost, elapsed=assistant_message.elapsed)
  end
  updated_content = state.skip_code_execution ? msg : update_message_with_outputs(msg)
  add_n_save_ai_message!(state, updated_content, ai_meta)

  println("\n\e[32m¬ \e[0m$(updated_content)")
  println("\e[32mAI message meta: \e[0m$(format_meta_info(ai_meta))")

  return curr_conv_msgs(state)[end]
end



