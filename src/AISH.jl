
module AISH

using EasyContext: Message, ConversationInfo, ConversationProcessor
using EasyContext: CodeBlock, format_shell_results_to_context
using EasyContext: greet, SYSTEM_PROMPT
using EasyContext: update_last_user_message_meta
using EasyContext: add_user_message!, add_ai_message!, add_error_message!
using EasyContext: wait_user_question, create_user_message, save!, reset!
using EasyContext: StreamingLLMProcessor, ConversationProcessorr
using EasyContext: ContextNode, CodeBlockExtractor, Persistable
using EasyContext: QuestionAccumulatorProcessor, CodebaseContextV3, ReduceRankGPTReranker, Workspace, CreateWorkspace
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: to_disk_custom!
using EasyContext: extract_and_preprocess_codeblocks
using EasyContext: LLM_conditonal_apply_changes
using EasyContext: get_processor_description

include("utils.jl")
include("arg_parser.jl")

include("AI_config.jl")
include("AI_prompt.jl")

function start_conversation(user_question=""; resume, streaming, project_paths, show_tokens, silent, loop=true)

  # init
  workspace    = CreateWorkspace(project_paths)
  llm_solve    = StreamingLLMProcessor()
  extractor    = CodeBlockExtractor()
  persister    = Persistable("")

  # codebase_context = ContextNode(tag="Codebase", element="File")
  
  # prepare
  print_project_tree(workspace, show_tokens=show_tokens)
  set_terminal_title("AISH $(workspace.common_path)")

  !silent && greet(ChatSH, llm_solve)
  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  !silent && isempty(user_question) && println("Your multiline input (empty line to finish):")

  shell_context    = ContextNode(tag="ShellRunResults", element="sh_script")
  codebase_context = ContextNode(tag="Codebase", element="File")
  package_context  = ContextNode(tag="Functions", element="Function")

  sys_msg_ext = SYSTEM_PROMPT(ChatSH)
  sys_msg_ext *= get_processor_description(:ShellResults,        shell_context)
  sys_msg_ext *= get_processor_description(:CodebaseContext,     codebase_context)
  sys_msg_ext *= get_processor_description(:JuliaPackageContext, package_context)
  conversation = ConversationProcessorr(sys_msggg=sys_msg_ext)

  _add_user_message!(msg)  = add_user_message!(conversation, msg)
  _add_ai_message!(msg)    = add_ai_message!(conversation, msg)
  _add_error_message!(msg) = add_error_message!(conversation, msg)
  to_disk!()               = to_disk_custom!(conversation, persister)


  # forward
  while loop || !isempty(user_question)

    user_question = wait_user_question(user_question)
    context_shell    = format_shell_results_to_context(extractor.shell_results)
    context_codebase = begin
        # question_acc = QuestionAccumulatorProcessor()(user_question)
        codebase = CodebaseContextV3(project_paths=workspace.project_paths)(user_question)
        reranked = ReduceRankGPTReranker(batch_size=30, model="gpt4om")(codebase)
        codebase_context(reranked)
    end
    
    context_combiner!(user_question, context_shell, context_codebase) |> _add_user_message!

    reset!(extractor)
    error = llm_solve(conversation;
          on_text    = (text)  -> extract_and_preprocess_codeblocks(text, extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
          on_meta_usr= (meta)  -> update_last_user_message_meta(conversation, meta),
          on_meta_ai = (ai_msg)-> (ai_msg |> _add_ai_message!; to_disk!()),
          on_done    = ()      -> codeblock_runner(extractor),
          on_error   = (error) -> ("\nERROR: $error" |> add_error_message!; to_disk!()),
    )

    user_question=""
  end
end

function start(message=""; resume=false, streaming=true, project_paths=String[], contexter=nothing, show_tokens=false, loop=true)
  nice_exit_handler()
  start_conversation(message; loop, resume, streaming, project_paths, show_tokens, silent=!isempty(message))
end

function main(;contexter=nothing, loop=true)
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
julia_main(;contexter=nothing, loop=true) = main(;contexter, loop)

export main, julia_main

include("precompile_scripts.jl")

end # module AISH
