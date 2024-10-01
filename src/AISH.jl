
module AISH

using Chain

using EasyContext: get_processor_description, ContextNode
using EasyContext: ConversationCTX
using EasyContext: Workspace, WorkspaceLoader
using EasyContext: format_shell_results_to_context
using EasyContext: greet, Context
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question, reset!
using EasyContext: workspace_ctx_2_string, julia_ctx_2_string, shell_ctx_2_string
using EasyContext: ChangeTracker, AgeTracker
using EasyContext: StreamingLLMProcessor
using EasyContext: CodeBlockExtractor, Persistable
using EasyContext: BM25IndexBuilder, EmbeddingIndexBuilder
using EasyContext: ReduceRankGPTReranker, QuestionCTX
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: to_disk_custom!
using EasyContext: extract_and_preprocess_codeblocks
using EasyContext: LLM_conditonal_apply_changes
using EasyContext: full_file_chunker
using EasyContext: workspace_format_description
using EasyContext: shell_format_description
using EasyContext: julia_format_description
using EasyContext: get_cache_setting
using EasyContext: FullFileChunker
using EasyContext: codeblock_runner
using EasyContext: OpenAIBatchEmbedder
using EasyContext

include("utils.jl")
include("arg_parser.jl")

include("AI_prompt.jl")

function start_conversation(user_question=""; resume, streaming, project_paths, logdir, show_tokens, silent, loop=true)

  # init
  workspace       = WorkspaceLoader(project_paths)
  extractor       = CodeBlockExtractor()
  # package_ctx     = JuliaPackageContext()
  llm_solve       = StreamingLLMProcessor()
  persister       = Persistable(logdir)

  workspace_ctx   = Context()
  ws_age!         = AgeTracker()
  ws_changes      = ChangeTracker()
  question_acc    = QuestionCTX()


  sys_msg         = SYSTEM_PROMPT(ChatSH)
  sys_msg        *= workspace_format_description()
  sys_msg        *= shell_format_description()
  sys_msg        *= julia_format_description()
  conv_ctx        = ConversationCTX_from_sysmsg(sys_msg=sys_msg)

  
  # prepare 
  print_project_tree(workspace, show_tokens=show_tokens)
  set_terminal_title("AISH $(workspace.common_path)")

  !silent && greet(ChatSH, llm_solve)
  isdefined(Base, :active_repl) && println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ")
  !silent && isempty(user_question) && println("Your multiline input (empty line to finish):")

  _add_error_message!(msg) = add_error_message!(conv_ctx, msg)
  to_disk!()               = to_disk_custom!(conv_ctx, persister)

  # forward
  while loop || !isempty(user_question)

    user_question   = isempty(user_question) ? wait_user_question(user_question) : user_question
    println("Thinking...")

    ctx_question    = user_question |> question_acc 
    ctx_shell       = extractor |> shell_ctx_2_string #format_shell_results_to_context(extractor.shell_results)
    ctx_codebase    = @chain workspace(FullFileChunker()) begin 
                        if isempty(_)
                          ""  
                        else
                          @chain _ begin
                            EmbeddingIndexBuilder()(_, ctx_question)
                            ReduceRankGPTReranker(batch_size=30, model="gpt4om")(_, ctx_question)
                            workspace_ctx
                            ws_age!(_, max_history=5)
                            ws_changes
                            workspace_ctx_2_string(_...)
                          end
                        end
    end
    # ctx_jl_pkg      = @chain JuliaPackageContext() begin
    #                       entr_tracker()
    #                       BM25IndexBuilder()(_, ctx_question)
    #                       ReduceRankGPTReranker(batch_size=40)(_, ctx_question)
    #                       jl_age(_, max_history=5)
    #                       jl_changes
    #                       julia_ctx_2_string
    # end
    
    query = context_combiner!(user_question, ctx_shell, ctx_codebase)

    conversation  = conv_ctx(create_user_message(query))

    reset!(extractor)
    user_question = ""


    cache = get_cache_setting(conv_ctx)
    error = llm_solve(conversation, cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> (conv_ctx(ai_msg); to_disk!()),
                      on_done     = ()       -> codeblock_runner(extractor),
                      on_error    = (error)  -> ((user_question = "ERROR: $error"); to_disk!()),
    )

    silent && break
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
julia_main(;loop=true) = main(;loop)

export main, julia_main

include("precompile_scripts.jl")

end # module AISH
