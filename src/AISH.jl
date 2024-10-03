
module AISH

using EasyContext: greet
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question, reset!
using EasyContext: LLM_solve
using EasyContext: CodeBlockExtractor, Persistable
using EasyContext: QuestionCTX
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: to_disk_custom!
using EasyContext: extract_and_preprocess_codeblocks
using EasyContext: LLM_conditonal_apply_changes
using EasyContext: get_cache_setting
using EasyContext: codeblock_runner
using EasyContext: init_workspace_context
using EasyContext: init_julia_context
using EasyContext: init_conversation_context
using EasyContext

include("utils.jl")
include("arg_parser.jl")

include("AI_prompt.jl")


function start_conversation(user_question=""; resume, streaming, project_paths, logdir, show_tokens, silent, loop=true)
  
  # init
  workspace_context = init_workspace_context(project_paths)
  julia_context     = init_julia_context()
  conv_ctx          = init_conversation_context()
  
  question_acc      = QuestionCTX()  
  extractor         = CodeBlockExtractor()
  persister         = Persistable(logdir)

  # prepare 
  print_project_tree(workspace_context.workspace, show_tokens=show_tokens)
  set_terminal_title("AISH $(workspace_context.workspace.common_path)")
  !silent && greet(ChatSH)
  !silent && isempty(user_question) && (isdefined(Base, :active_repl) ? println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ") : println("Your multiline input (empty line to finish):"))

  to_disk!()        = to_disk_custom!(conv_ctx, persister)

  # forward
  while loop || !isempty(user_question)

    user_question = isempty(user_question) ? wait_user_question(user_question) : user_question
    !silent && println("Thinking...")  # Only print if not silent

    ctx_question = user_question |> question_acc 
    ctx_shell    = extractor |> shell_ctx_2_string
    ctx_codebase = @async process_workspace_context(workspace_context, ctx_question)
    ctx_jl_pkg   = @async process_julia_context(julia_context, ctx_question)

    query = context_combiner!(
      user_question, 
      ctx_shell, 
      fetch(ctx_codebase), 
      fetch(ctx_jl_pkg)
    )

    conversation = conv_ctx(create_user_message(query))

    reset!(extractor)
    user_question = ""

    cache = get_cache_setting(conv_ctx)
    error = LLM_solve(conversation, cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> (conv_ctx(ai_msg); to_disk!()),
                      on_done     = ()       -> codeblock_runner(extractor),
                      on_error    = (error)  -> (add_error_message!(conv_ctx,"ERROR: $error"); to_disk!()),
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

