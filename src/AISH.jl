# src/AISH.jl
module AISH

using REPL
using InteractiveUtils
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage

include("AI_config.jl")
include("AI_prompt.jl")
include("AI_struct.jl")
include("arg_parser.jl")

include("error_managers/anthropic_error_handler.jl")

include("input_source/speech2text.jl")
include("input_source/dummy_text.jl")
include("input_source/keyboard.jl")
include("input_source/detect_command.jl")

include("user_messages.jl")

include("process_query.jl")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))

function start_conversation(state::AIState; resume::Bool=true)
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,)))

  println("Welcome to $ChatSH AI. Model: $(state.model)")

  while !isempty(state.conversation) && state.conversation[end] isa UserMessage
    pop!(state.conversation)
  end

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

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  println("Your multiline input (empty line to finish):")
  while true
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    # user_message = speech2text()
    # user_message = get_random_speech()
    user_message = readline_improved()
    print("\e[0m")  # reset text style

    add_user_message!(state, user_message)
    length(state.conversation) > 12 && (state.conversation = [state.conversation[1], state.conversation[4:end]...])
    process_question(state)
  end
end

function main()
  args = parse_commandline()
  set_project_path(args["project-path"])
  ai_state = initialize_ai_state()
  start_conversation(ai_state, resume=args["resume"])
  ai_state
end

end # module AISH
