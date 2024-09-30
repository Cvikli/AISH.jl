
module AISH

using Pipe

using EasyContext: get_processor_description, ContextNode
using EasyContext: ConversationProcessor, ConversationProcessorr
using EasyContext: Workspace, CreateWorkspace
using EasyContext: format_shell_results_to_context
using EasyContext: greet, Context
using EasyContext: update_last_user_message_meta
using EasyContext: add_user_message!, add_ai_message!, add_error_message!
using EasyContext: wait_user_question, reset!
using EasyContext: workspace_ctx_2_string, julia_ctx_2_string, shell_ctx_2_string
using EasyContext: ChangeTracker, AgeTracker
using EasyContext: StreamingLLMProcessor
using EasyContext: CodeBlockExtractor, Persistable
using EasyContext: BM25IndexBuilder, EmbeddingIndexBuilder
using EasyContext: ReduceRankGPTReranker, QuestionAccumulatorProcessor
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: to_disk_custom!
using EasyContext: extract_and_preprocess_codeblocks
using EasyContext: LLM_conditonal_apply_changes
using EasyContext: full_file_chunker
using EasyContext: CTX_wrapper, CTX_unwrapp
using EasyContext: workspace_format_description
using EasyContext: shell_format_description
using EasyContext: julia_format_description
using EasyContext: get_cache_setting
using EasyContext: FullFileChunker
using EasyContext: codeblock_runner

include("utils.jl")
include("arg_parser.jl")

include("AI_prompt.jl")

function start_conversation(user_question=""; resume, streaming, project_paths, logdir, show_tokens, silent, loop=true)

  # init
  workspace       = CreateWorkspace(project_paths)
  extractor       = CodeBlockExtractor()
  # package_ctx     = JuliaPackageContext()
  llm_solve       = StreamingLLMProcessor()
  persister       = Persistable(logdir)
  ws_age          = AgeTracker()
  ws_changes      = ChangeTracker()
  workspace_ctx   = Context()
  question_acc    = QuestionAccumulatorProcessor()

  sys_msg         = SYSTEM_PROMPT(ChatSH)
  sys_msg        *= workspace_format_description() # get_processor_description(:CodebaseContext,     codebase_context)
  sys_msg        *= shell_format_description() # get_processor_description(:ShellResults,        shell_context)
  sys_msg        *= julia_format_description() # get_processor_description(:JuliaPackageContext, package_context)
  conversation    = ConversationProcessorr(sys_msg=sys_msg)

  
  # prepare
  print_project_tree(workspace, show_tokens=show_tokens)
  set_terminal_title("AISH $(workspace.common_path)")

  !silent && greet(ChatSH, llm_solve)
  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  !silent && isempty(user_question) && println("Your multiline input (empty line to finish):")

  # shell_context    = ContextNode(tag="ShellRunResults", element="sh_script")
  # codebase_context = ContextNode(tag="Codebase", element="File")
  # package_context  = ContextNode(tag="Functions", element="Function")
  
  _add_user_message!(msg)     = add_user_message!(conversation, msg)
  _add_ai_message!(msg)       = add_ai_message!(conversation, msg)
  _add_error_message!(msg)    = add_error_message!(conversation, msg)
  to_disk!()                  = to_disk_custom!(conversation, persister)

  # forward
  while loop || !isempty(user_question)

    user_question   = wait_user_question(user_question)

    ctx_question    = user_question |> question_acc 
    ctx_shell       = extractor |> shell_ctx_2_string #format_shell_results_to_context(extractor.shell_results)
    ctx_codebase    = begin 
                        _0 = workspace(FullFileChunker())
                        if isempty(_0) 
                          ""  
                        else
                          _1 = CTX_unwrapp(EmbeddingIndexBuilder()(CTX_wrapper(_0,ctx_question)))
                          _2 = CTX_unwrapp(ReduceRankGPTReranker(batch_size=30, model="gpt4om")(CTX_wrapper(_1, ctx_question)))
                          _3 = workspace_ctx(_2)
                          _4 = ws_age(_3, max_history=5)
                          _5 = ws_changes(_4)
                          _6 = workspace_ctx_2_string(_5...)
                        end
    end
    # ctx_jl_pkg      = @pipe (JuliaPackageContext()
    #                       |> entr_tracker()
    #                       |> BM25IndexBuilder()(_, ctx_question)
    #                       |> ReduceRankGPTReranker(batch_size=40)(_, ctx_question)
    #                       |> age_filter
    #                       |> changes_tracker
    #                       |> julia_ctx_2_string)
    
    context_combiner!(user_question, ctx_shell, ctx_codebase) |> _add_user_message!

    reset!(extractor)

    cache = get_cache_setting(conversation)
    error = llm_solve(conversation(), cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(conversation, meta),
                      on_meta_ai  = (ai_msg) -> (ai_msg |> _add_ai_message!; to_disk!()),
                      on_done     = ()       -> codeblock_runner(extractor),
                      on_error    = (error)  -> ("\nERROR: $error" |> add_error_message!; to_disk!()),
    )

    user_question=""
  end
end

function start(message=""; resume=false, streaming=true, project_paths=String[], logdir="", contexter=nothing, show_tokens=false, loop=true)
  nice_exit_handler()
  start_conversation(message; loop, resume, streaming, project_paths, logdir, show_tokens, silent=!isempty(message))
end

function main(;contexter=nothing, loop=true)
  args = parse_commandline()
  start(args["message"]; 
        resume=args["resume"], 
        streaming=!args["no-streaming"], 
        project_paths=args["project-paths"], 
        show_tokens=args["tokens"], 
        logdir=args["log-dir"], 
        loop=!args["no-loop"] && loop, 
        contexter=contexter,
  )
end
julia_main(;contexter=nothing, loop=true) = main(;contexter, loop)

export main, julia_main

include("precompile_scripts.jl")

end # module AISH
