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

include("input_source/keyboard.jl")

include("messages.jl")

include("process_query.jl")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))

function start_conversation(state::AIState; resume::Bool=true)
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,)))

  println("Welcome to $ChatSH AI. Model: $(state.model)")

  while !isempty(cur_conv(state)) && cur_conv(state)[end].role == :user; pop!(cur_conv(state)); end

  if resume
    loaded_conversation = load_conversation(state.selected_conv_id)
    if !isempty(loaded_conversation)
      state.conversation[state.selected_conv_id] = loaded_conversation
      println("Resumed conversation with ID: $(state.selected_conv_id)")
      if should_append_new_message(loaded_conversation)
        process_question(state)
      end
    else
      println("No previous conversation found. Starting a new conversation.")
    end
  end

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  println("Your multiline input (empty line to finish):")
  while true
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    user_message = readline_improved()
    print("\e[0m")  # reset text style

    add_user_message!(state, user_message)
    limit_user_messages(state)
    
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
