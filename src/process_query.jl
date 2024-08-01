using PromptingTools: AIMessage

process_query(ai_state, user_message) = begin
  add_user_message!(ai_state, user_message)
  save_user_message(ai_state.selected_conv_id, user_message)
  process_question(ai_state)
  save_ai_message(ai_state.selected_conv_id, response)
  response
end
function process_question(state::AIState)
  println("Thinking...")

  assistant_message = safe_aigenerate(cur_conv(state), model=state.model)
  # println("\e[32m¬ \e[0m$(assistant_message.content)")
  # println()

  updated_content = update_message_with_outputs(assistant_message.content)
  println("\e[32m¬ \e[0m$(updated_content)")

  push!(cur_conv(state), AIMessage(updated_content,
    assistant_message.status,
    assistant_message.tokens,
    assistant_message.elapsed,
    assistant_message.cost,
    assistant_message.log_prob,
    assistant_message.finish_reason,
    assistant_message.run_id,
    assistant_message.sample_id,
    assistant_message._type))

  # Save AI message
  save_ai_message(state.selected_conv_id, updated_content)

  update_system_prompt!(state)
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
