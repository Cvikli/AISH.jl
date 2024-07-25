using PromptingTools: AIMessage

function process_question(state::AIState)
  println("Thinking...")

  assistant_message = safe_aigenerate(state.conversation, model=state.model)
  println("\e[32m¬ \e[0m$(assistant_message.content)")
  println()

  updated_content = update_message_with_outputs(assistant_message.content)
  println(updated_content)

  push!(state.conversation, AIMessage(updated_content, 
                                      assistant_message.status,
                                      assistant_message.tokens,
                                      assistant_message.elapsed,
                                      assistant_message.cost,
                                      assistant_message.log_prob,
                                      assistant_message.finish_reason,
                                      assistant_message.run_id,
                                      assistant_message.sample_id,
                                      assistant_message._type))

  update_system_prompt!(state)
end

function update_message_with_outputs(content)
  return replace(content, r"```sh\n([\s\S]*?)\n```" => matchedtxt -> begin
    code = matchedtxt[7:end-3]
    output = execute_code_block(code)
    "$matchedtxt\n```sh_run_results\n$output\n```\n"
  end)
end

function execute_code_block(code)
  isconfirming = startswith(code, "read")
  withenv("GTK_PATH" => "") do
    try
      shell = isconfirming ? "zsh" : "bash" # We use BASH most of the case. But for confirming the 'cat' we have to use zsh as it supports this arguments 
      return strip(read(`$shell -c $code`, String))
    catch error
      error isa ProcessFailedException && !isempty(error.procs) && error.procs[1].exitcode == 1 && isconfirming && return "ProcessExited(1) which can be still okay, we just cancelled the run"
      error_output = strip(sprint(showerror, error))
      @warn("Error occurred during execution: $error_output")
      return "[Error] $error_output\n"
    end
  end
end

