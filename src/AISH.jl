
module AISH

using Dates
using UUIDs
using SHA

# Lazy load heavy dependencies
# const DataStructures = Base.require(Base.PkgId(Base.UUID("864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"), "DataStructures"))
# const PromptingTools = Base.require(Base.PkgId(Base.UUID("670122d1-24a8-4d70-bfce-740807c42192"), "PromptingTools"))
using DataStructures
using PromptingTools

# Import the ProgressMeter for progress tracking
using ProgressMeter

# Only import what's necessary from BoilerplateCvikli
using BoilerplateCvikli: @async_showerr

using Anthropic
using Anthropic: initStreamMeta, StreamMeta, calc_elapsed_times, format_meta_info


include("utils.jl")
include("keyboard.jl")

include("output_codeblock.jl")
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


function start_conversation(state::AIState, user_question=""; loop=true)
  !state.silent && println("Welcome to $ChatSH AI. (using $(state.model))")

  while !isempty(curr_conv_msgs(state)) && curr_conv_msgs(state)[end].role == :user; pop!(curr_conv_msgs(state)); end

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  !state.silent && println("Your multiline input (empty line to finish):")

  shell_results = Dict{String, CodeBlock}()
  if !isempty(strip(user_question)) 
    # println("\e[36m➜ \e[1m$(user_question)\e[0m")
    _, shell_results = streaming_process_question(state, user_question, shell_results)
  end

  while loop
    print("\e[36m➜ \e[0m")  # teal arrow
    print("\e[1m")  # bold text
    user_question = readline_improved()
    print("\e[0m")  # reset text style
    isempty(strip(user_question)) && continue
    
    _, shell_results = streaming_process_question(state, user_question, shell_results)
  end
end

function start(message=""; resume=false, streaming=true, project_paths=String[], contexter=SimpleContexter(), show_tokens=false, loop=true)
  ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,))) # Nice program exit for ctrl + c.
  ai_state = initialize_ai_state(;contexter, resume, streaming, project_paths, show_tokens, silent=!isempty(message))

  set_terminal_title("AISH $(curr_conv(ai_state).common_path)")
  
  start_conversation(ai_state, message; loop)
  ai_state
end

julia_main(;contexter=SimpleContexter(), loop=true) = main(;contexter, loop)
function main(;contexter=SimpleContexter(), loop=true)
  args = parse_commandline()
  start(args["message"]; 
      resume=args["resume"], 
      streaming=!args["no-streaming"], 
      project_paths=args["project-paths"], 
      show_tokens=args["tokens"], 
      loop=!args["no-loop"] && loop, 
      contexter=contexter,
  )
end

export main

include("precompile_scripts.jl")

end # module AISH
