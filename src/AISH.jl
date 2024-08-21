module AISH

using Dates

using PromptingTools
using Anthropic
using Anthropic: channel_to_string, initStreamMeta, StreamMeta, calc_elapsed_times, format_meta_info

include("AI_config.jl")
include("AI_prompt.jl")
include("AIState.jl")
include("project_management.jl")
include("project_tree.jl")
include("arg_parser.jl")

include("anthropic_extension.jl")

include("keyboard.jl")

include("file_operations.jl")

include("messages.jl")

include("execute.jl")
include("process_query.jl")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))


function start_conversation(state::AIState)
  println("Welcome to $ChatSH AI. (using $(state.model))")

  while !isempty(curr_conv_msgs(state)) && curr_conv_msgs(state)[end].role == :user; pop!(curr_conv_msgs(state)); end

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  println("Your multiline input (empty line to finish):")
  while true
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    user_message = readline_improved()
    print("\e[0m")  # reset text style
    isempty(strip(user_message)) && continue
    
    process_question(state, user_message)
  end
end

function start(;resume=false, streaming=true, project_paths=String[])
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,))) # Nice program exit for ctrl + c.
  ai_state = initialize_ai_state(;resume, streaming, project_paths)
  start_conversation(ai_state)
  ai_state
end

function main()
  args = parse_commandline()
  start(resume=args["resume"], streaming=args["streaming"], project_paths=args["project-paths"])
end

end # module AISH
