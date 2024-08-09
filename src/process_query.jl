streaming_process_query(ai_state::AIState, user_message) = begin
  add_n_save_user_message!(ai_state, user_message)
  ai_stream_safe(ai_state, model=ai_state.model)
end

process_query(ai_state::AIState, user_message) = begin
  add_n_save_user_message!(ai_state, user_message)
  response = process_question(ai_state)
  add_n_save_ai_message!(ai_state, response)
  response
end

function process_question(state::AIState)
  update_system_prompt!(state)

  if state.streaming
    print("\e[32m¬ \e[0m")
    full_response = Anthropic.ai_stream_safe(state) 
    msg = channel_to_string(full_response)
  else
    println("Thinking...")  
    assistant_message = anthropic_ask_safe(state)
    msg = assistant_message.content
  end
  updated_content = update_message_with_outputs(msg)
  println("\n\e[32m¬ \e[0m$(updated_content)")

  add_n_save_ai_message!(state, updated_content)

  return cur_conv_msgs(state)[end]
end


update_message_with_outputs(content) = return replace(content, r"```sh\n([\s\S]*?)\n```" => matchedtxt -> begin
  code = matchedtxt[7:end-3]
  output = execute_code_block(code)
  "$matchedtxt\n```sh_run_results\n$output\n```\n"
end)

function execute_code_block(code)
  isconfirming = startswith(code, "read")
  withenv("GTK_PATH" => "") do
    shell = isconfirming ? "zsh" : "bash" # We use BASH most of the case. But for confirming the 'cat' we have to use zsh as it supports this arguments
    println("\e[32m$code\e[0m")
    return cmd_all_info(`$shell -c $code`)
  end
end

function cmd_all_info(cmd::Cmd, output=IOBuffer(), error=IOBuffer())
  err = nothing
  process = nothing
  try
    process = run(pipeline(ignorestatus(cmd), stdout=output, stderr=error))
  catch e
    err = e
  end
  return "$((
    stdout=String(take!(output)),
    stderr=String(take!(error)),
    exit_code=isnothing(process) ? -1 : process.exitcode,
    exception=err
  ))"
end
