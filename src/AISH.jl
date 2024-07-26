# src/AISH.jl
module AISH

using REPL
using InteractiveUtils
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage

include("includes.jl")

function start_conversation(state::AIState; resume::Bool=true)
  println("Welcome to $ChatSH AI. Model: $(state.model)")
  
  while !isempty(state.conversation) && state.conversation[end] isa UserMessage; pop!(state.conversation); end

  if resume
    last_message = get_last_user_message()
    if !isempty(last_message)
      println("Resuming with last user message: $last_message")
      add_user_message!(state, last_message, save_message=false)
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
  
    add_user_message!(state, user_message)
    length(state.conversation) > 12 && (state.conversation = [state.conversation[1],state.conversation[4:end]...])
    println()
    process_question(state)
  end
end

function main()
    args = parse_commandline()
    set_project_path(args["project-path"])
    state = initialize_ai_state()
    start_conversation(state)
end

end # module AISH
