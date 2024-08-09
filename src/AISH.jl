# src/AISH.jl
module AISH

using REPL
using InteractiveUtils
using PromptingTools
using Dates

include("AI_config.jl")
include("AI_prompt.jl")
include("AI_struct.jl")
include("arg_parser.jl")

include("anthropic/error_handler.jl")
include("anthropic/streaming.jl")

include("input_source/keyboard.jl")

include("messages.jl")

include("process_query.jl")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))

function start_conversation(state::AIState)
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,)))

  println("Welcome to $ChatSH AI. Model: $(state.model)")

  while !isempty(cur_conv_msgs(state)) && cur_conv_msgs(state)[end].role == :user; pop!(cur_conv_msgs(state)); end

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  println("Your multiline input (empty line to finish):")
  while true
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    user_message = readline_improved()
    print("\e[0m")  # reset text style
    isempty(strip(user_message)) && continue
    add_n_save_user_message!(state, user_message)
    limit_user_messages(state)
    
    process_question(state)
  end
end

function main()
  args = parse_commandline()
  set_project_path(args["project-path"])
  ai_state = initialize_ai_state(resume=args["resume"])
  start_conversation(ai_state)
  ai_state
end

end # module AISH
