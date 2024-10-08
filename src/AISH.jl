
module AISH

using BoilerplateCvikli: @async_showerr
using EasyContext: greet
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question, reset!
using EasyContext: LLM_solve
using EasyContext: CodeBlockExtractor, Persistable
using EasyContext: QuestionCTX
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: extract_and_preprocess_codeblocks
using EasyContext: LLM_conditonal_apply_changes, LLM_reflect
using EasyContext: get_cache_setting
using EasyContext: codeblock_runner
using EasyContext: shell_ctx_2_string, test_ctx_2_string
using EasyContext: init_workspace_context
using EasyContext: init_conversation_context
using EasyContext: process_workspace_context
using EasyContext: process_julia_context
using EasyContext: cut_old_history!
using EasyContext: shell_format_description, workspace_format_description, julia_format_description, test_format_description
using EasyContext: last_msg, init_testframework
using EasyContext: is_continue
using EasyContext

include("utils.jl")
include("arg_parser.jl")

include("AI_prompt.jl")


function start_conversation(user_question=""; resume, project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true, test_cases="", test_filepath="")
  
  # init
  persister         = Persistable(logdir)
  julia_context     = init_julia_context()
  conv_ctx          = init_conversation_context(SYSTEM_PROMPT(ChatSH))
  test_frame        = init_testframework(persister, conv_ctx, test_cases, test_filepath)
  workspace_context = init_workspace_context(project_paths, append_files=[test_frame.filename])
  
  age_tracker       = AgeTracker(max_history=14, cut_to=6)
  question_acc      = QuestionCTX()
  extractor         = CodeBlockExtractor()
  LLM_reflection    = ""
  
  # prepare 
  print_project_tree(workspace_context.workspace, show_tokens=show_tokens)
  set_terminal_title("AISH $(workspace_context.workspace.root_path)")
  !silent && greet(ChatSH)
  !silent && isempty(user_question) && (isdefined(Base, :active_repl) ? println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ") : println("Your multiline input (empty line to finish):"))
  
  append_ctx_descriptors(conv_ctx, shell_format_description(), workspace_format_description(), julia_format_description(), test_format_description(test_frame))
  
  ctx_test          = run_tests(test_frame) |> test_ctx_2_string
  ctx_shell      = extractor |> shell_ctx_2_string

  # forward
  while loop || !isempty(user_question)  || !isempty(LLM_reflection) 
    @show loop
    user_question = !isempty(LLM_reflection) ? LLM_reflection : 
                    !isempty(user_question)  ? user_question  : wait_user_question(user_question)
    !silent && println("Thinking...")  # Only print if not silent
    
    ctx_question   = user_question |> question_acc
    ctx_codebase   = @async_showerr process_workspace_context(workspace_context, ctx_question; age_tracker)
    ctx_jl_pkg     = @async_showerr process_julia_context(julia_context, ctx_question; age_tracker)

    query = context_combiner!(
      user_question, 
      ctx_shell, 
      ctx_test, 
      fetch(ctx_codebase), 
      fetch(ctx_jl_pkg),
    )

    conv_ctx(create_user_message(query))

    reset!(extractor)
    user_question = ""

    cache = get_cache_setting(age_tracker, conv_ctx)
    error = LLM_solve(conv_ctx, cache;
                      on_text     = (text)   -> extract_and_preprocess_codeblocks(text, extractor, preprocess=(cb)->LLM_conditonal_apply_changes(cb)),
                      on_meta_usr = (meta)   -> update_last_user_message_meta(conv_ctx, meta),
                      on_meta_ai  = (ai_msg) -> conv_ctx(ai_msg),
                      on_done     = ()       -> (codeblock_runner(extractor, no_confirm=no_confirm)),
                      on_error    = (error)  -> add_error_message!(conv_ctx,"ERROR: $error"),
    )

    ctx_test       = run_tests(test_frame) |> test_ctx_2_string
    @show "----------ctx_test"
    println(ctx_test)
    ctx_shell      = extractor |> shell_ctx_2_string
    LLM_answer     = LLM_reflect(ctx_question, ctx_shell, ctx_test, last_msg(conv_ctx))
    println("-------LLM stuff")
    println(LLM_answer)
    LLM_reflection = is_continue(LLM_reflect_condition(LLM_answer)) ? LLM_answer : ""

    cut_old_history!(age_tracker, conv_ctx, julia_context, workspace_context, )

    silent && break
  end
end

function start(message=""; resume=false, project_paths=String[], logdir="conversations", show_tokens=false, no_confirm=false, loop=true, test_cases="", test_filepath="")
  nice_exit_handler()
  start_conversation(message, silent=!isempty(message); loop, resume, project_paths, logdir, show_tokens, no_confirm, test_cases, test_filepath)
end

function main(;loop=true)
  args = parse_commandline()
  start(args["message"]; 
        resume=args["resume"], 
        project_paths=args["project-paths"], 
        show_tokens=args["tokens"], 
        logdir=args["log-dir"], 
        loop=!args["no-loop"] && loop, 
        no_confirm=args["no-confirm"],
  )
end
julia_main(;loop=true) = main(;loop)

export main, julia_main

include("precompile_scripts.jl")

end # module AISH

