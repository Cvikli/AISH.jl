# src/AISH.jl
module AISH

using REPL
using InteractiveUtils
using PromptingTools
using PromptingTools: SystemMessage, UserMessage

include("includes.jl")

function start_conversation(state::AIState; resume::Bool=true)
  println("Welcome to $ChatSH AI. Model: $(state.model)")
  
  if resume
    last_message = get_last_user_message()
    if !isnothing(last_message)
      println("Resuming with last user message: $last_message")
      push!(state.conversation, UserMessage(strip(last_message)))
      process_question(state)
    else
      println("No previous message found. Starting a new conversation.")
    end
  end
  
  println("Press [Enter] then you can start the conversation!")
  while true
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    # user_message = speech2text()
    # user_message = get_random_speech()
    user_message = readline_improved()
    print("\e[0m")  # reset text style
  
    push!(state.conversation, UserMessage(strip(user_message)))
    save_user_message(state.conversation[end].content)
    length(state.conversation) > 12 && (state.conversation = [state.conversation[1],state.conversation[4:end]...])
    println()
    process_question(state)
  end
end

end # module AISH
