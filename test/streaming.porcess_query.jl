
function process_question(state::AIState)
  assistant_message = safe_aigenerate(state.conversation, model=state.model)
  print("\e[32m¬ \e[0m")
  assistant_message = stream_anthropic_response(state.conversation, model=state.model)

  updated_content = update_message_with_outputs(assistant_message)
  println(updated_content)

  push!(state.conversation, AIMessage(updated_content))

  update_system_prompt!(state)
end
