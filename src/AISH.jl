module AISH

using Dates

using PromptingTools
using Anthropic
using Anthropic: channel_to_string, initStreamMeta, StreamMeta

include("AI_config.jl")
include("AI_prompt.jl")
include("AIState.jl")
include("arg_parser.jl")

include("anthropic_extension.jl")

include("keyboard.jl")

include("messages.jl")

include("process_query.jl")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))

function initialize_project_path(ai_state::AIState)
    if ai_state.project_path !== ""
        cd(ai_state.project_path)
        ai_state.project_path = pwd()
        println("Project path initialized: ")
    end
end

function set_project_path(ai_state::AIState, new_path::String)
    if isdir(new_path)
        ai_state.project_path = abspath(new_path)
        cd(ai_state.project_path)
        println("Project path updated: ")
    else
        error("Invalid project path: ")
    end
end

function start_conversation(state::AIState)
  println("Welcome to $ChatSH AI. (using $(state.model))")

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
    # limit_user_messages(state)
    
    process_question(state)
  end
end

function start(;resume=false, streaming=true, project_path="")
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,))) # Nice program exit for ctrl + c.
  ai_state = initialize_ai_state(;resume, streaming, project_path)
  start_conversation(ai_state)
  ai_state
end

function main()
  args = parse_commandline()
  start(resume=args["resume"], streaming=args["streaming"], project_path=args["project-path"])
end

end # module AISH
