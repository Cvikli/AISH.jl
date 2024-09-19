module AISH

using Dates
using UUIDs

using DataStructures

using PromptingTools
using Anthropic
using Anthropic: initStreamMeta, StreamMeta, calc_elapsed_times, format_meta_info

using BoilerplateCvikli: @async_showerr

include("utils.jl")
include("keyboard.jl")

include("AI_config.jl")
include("AI_prompt.jl")
include("AI_contexter.jl")
include("AIState.jl")

include("token_counter.jl")
include("file_management.jl")
include("file_tree.jl")
include("file_operations.jl")
include("file_messages.jl")
include("arg_parser.jl")

include("anthropic_extension.jl")

include("shell_processing_ai.jl")
include("shell_processing.jl")

include("execute.jl")
include("process_query.jl")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))


function start_conversation(state::AIState, user_question="")
  println("Welcome to $ChatSH AI. (using $(state.model))")

  while !isempty(curr_conv_msgs(state)) && curr_conv_msgs(state)[end].role == :user; pop!(curr_conv_msgs(state)); end

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  println("Your multiline input (empty line to finish):")

  shell_results = Dict{String, String}()
  if !isempty(strip(user_question)) 
    println("\e[36m➜ \e[1m$(user_question)\e[0m")
    _, shell_results = process_question(state, user_question, shell_results)
  end

  while true
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    user_question = readline_improved()
    print("\e[0m")  # reset text style
    isempty(strip(user_question)) && continue
    
    _, shell_results = process_question(state, user_question, shell_results)
  end
end

function start(message=""; resume=false, streaming=true, project_paths=String[], contexter=SimpleContexter(), show_tokens=false)
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,))) # Nice program exit for ctrl + c.
  ai_state = initialize_ai_state(;contexter, resume, streaming, project_paths, show_tokens)
  
  set_terminal_title("AISH $(curr_conv(ai_state).common_path)")
  
  start_conversation(ai_state, message)
  ai_state
end

function main(;contexter=SimpleContexter())
  args = parse_commandline()
  start(args["message"]; resume=args["resume"], streaming=!args["no-streaming"], project_paths=args["project-paths"], show_tokens=args["tokens"], contexter)
end

export main

end # module AISH
