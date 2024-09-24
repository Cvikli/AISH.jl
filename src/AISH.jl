
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
include("processors.jl")




function start_conversation(state::AIState, user_question=""; loop=true)
  !state.silent && println("Welcome to $ChatSH AI. (using $(state.model))")

  while !isempty(curr_conv_msgs(state)) && curr_conv_msgs(state)[end].role == :user; pop!(curr_conv_msgs(state)); end

  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  !state.silent && println("Your multiline input (empty line to finish):")
  
  ssave!(msg) = save!(conversation, msg)

  workspace    = Workspace()
  conversation = ConversationProcessor()
  llm_solve    = StreamingLLMProcessor("sonnet-3.5")
  extractor    = CodeBlockExtractor()

  while loop || !isempty(user_question)

    user_question = wait_user_question(user_question)
    # stop_spinner = progressing_spinner()

    context_shell = @async_showerr format_shell_results_to_context(shell_scripts)
    context_codebase = @async_showerr begin
        question_acc = QuestionAccumulatorProcessor()(user_question)
        codebase = CodebaseContextV3(project_paths=workspace.project_paths)(question_acc)
        reranked = ReduceRankGPTReranker(batch_size=30, model="gpt4om")(codebase)
        model.codebase_context(reranked)
    end

    
    context_combiner!(user_question, context_shell, context_codebase) |> create_user_message |> ssave!
    @async_showerr persist!(conversation)

    reset!(extractor)
    error = llm_solve(user_msg;
          on_text    = (text)  -> extract_and_preprocess_codeblocks(text, extractor),
          on_meta_usr= (meta)  -> begin
            # stop_spinner[] = true; 
            # clearline();
            update_last_user_message_meta(conversation, meta)
          end,
          on_meta_ai=  (ai_msg)-> (ai_msg |> save!; persist!(conversation)),
          on_done   =  ()      -> codeblock_runner(extractor),
          on_error  =  (error) -> begin
            # stop_spinner[] = true;
            save_error!(conversation, "\nERROR: $error")
          end,
    )
    

    user_question=""
  end
end

function start(message=""; resume=false, streaming=true, project_paths=String[], contexter=SimpleContexter(), show_tokens=false, loop=true)
  nice_exit_handler()

  set_terminal_title("AISH $(project_paths[1])")
  
  start_conversation(ai_state, message; loop, contexter, resume, streaming, project_paths, show_tokens, silent=!isempty(message))
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
