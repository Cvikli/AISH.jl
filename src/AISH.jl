
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
include("Message.jl")
# include("AIState.jl")

include("processors.jl")
include("processor_conversation.jl")
include("processor_LLM.jl")
include("processor_persistable.jl")
include("processor_workspace.jl")

include("token_counter.jl")
include("file_management.jl")
include("file_tree.jl")
include("file_operations.jl")
# include("file_messages.jl")
include("arg_parser.jl")

include("anthropic_extension.jl")

include("shell_processing_ai.jl")
include("shell_processing.jl")

include("execute.jl")


function format_shell_results_to_context(shell_commands::AbstractDict{String, CodeBlock})
  content = ""
  for (code, codeblock) in shell_commands
      shortened_code = get_shortened_code(codestr(code))
      content *= """
      <sh_script shortened>
      $shortened_code
      </sh_script>
      <sh_output>
      $(codeblock.results[end])
      </sh_output>
      """
  end
  content = """
  <ShellResults>
  $content
  </ShellResults>
  """
  return content
end



function start_conversation(user_question="", workspace=CreateWorkspace(); resume, streaming, project_paths, show_tokens, silent, loop=true)

  # init
  conversation = ConversationProcessorrrr(sys_msggg="You are AI SH a shell...")
  llm_solve    = StreamingLLMProcessor()
  extractor    = CodeBlockExtractor()
  persister    = Persistable("")

  # codebase_context = ContextNode(tag="Codebase", element="File")
  
  # prepare
  !silent && greet(llm_solve)
  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  !silent && isempty(user_question) && println("Your multiline input (empty line to finish):")

  append_conv!(msg) = save!(conversation, msg)
  to_disk!()        = to_disk_custom!(conversation, persister)

  # forward
  while loop || !isempty(user_question)

    user_question = wait_user_question(user_question)
    # stop_spinner = progressing_spinner()

    context_shell    = format_shell_results_to_context(extractor.shell_results)
    context_codebase = begin
        # question_acc = QuestionAccumulatorProcessor()(user_question)
        # codebase = CodebaseContextV3(project_paths=workspace.project_paths)(question_acc)
        # reranked = ReduceRankGPTReranker(batch_size=30, model="gpt4om")(codebase)
        # codebase_context(reranked)
    end

    
    context_combiner!(user_question, context_shell, context_codebase) |> create_user_message |> append_conv!

    reset!(extractor)
    error = llm_solve(conversation;
          on_text    = (text)  -> extract_and_preprocess_codeblocks(text, extractor),
          on_meta_usr= (meta)  -> update_last_user_message_meta(conversation, meta),
          on_meta_ai = (ai_msg)-> (ai_msg |> append_conv!; to_disk!()),
          on_done    = ()      -> codeblock_runner(extractor),
          on_error   = (error) -> (save_error!(conversation, "\nERROR: $error") |> append_conv!; to_disk!()),
    )

    user_question=""
  end
end

function start(message=""; resume=false, streaming=true, project_paths=String[], contexter=SimpleContexter(), show_tokens=false, loop=true)
  nice_exit_handler()
  workspace    = CreateWorkspace(project_paths)
  set_terminal_title("AISH $(workspace.common_path)")
  
  start_conversation(message, workspace; loop, resume, streaming, project_paths, show_tokens, silent=!isempty(message))
end

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
julia_main(;contexter=SimpleContexter(), loop=true) = main(;contexter, loop)

export main, julia_main

include("precompile_scripts.jl")

end # module AISH
