
module AISH

using BoilerplateCvikli: @async_showerr
using EasyContext: greet
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question, reset!
using EasyContext: LLM_solve
using EasyContext: CodeBlockExtractor
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
using EasyContext: shell_format_description, workspace_format_description, julia_format_description
using EasyContext: last_msg
using EasyContext: is_continue
using EasyContext: ConversationX, TestFramework, PersistableState
using EasyContext: merge_git
using EasyContext

include("utils.jl")
include("config.jl")
include("arg_parser.jl")

include("AI_prompt.jl")
include("workflow/SR_loop.jl")
include("workflow/STD_loop.jl")



function start_conversation(user_question=""; resume, project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true)
  !silent && greet(ChatSH)

  # model = AIModel(project_paths)
  model = SRWorkFlow(;resume, project_paths, logdir, show_tokens, silent, no_confirm)

  set_terminal_title("AISH $(model.workspace_context.workspace.root_path)")

  !silent && isempty(user_question) && (isdefined(Base, :active_repl) ? println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ") : println("Your multiline input (empty line to finish):"))

  while loop || !isempty(user_question)
    user_question = isempty(user_question) ? wait_user_question(user_question) : user_question
    !silent && println("Thinking...")  # Only print if not silent
    
    result = model(user_question)
    result == :MERGE && merge_git(model.version_control)

    user_question = ""
  end
end

function start(message=""; resume=false, project_paths=String[], logdir=LOGDIR, show_tokens=false, no_confirm=false, loop=true)
  nice_exit_handler()
  start_conversation(message, silent=!isempty(message); loop, resume, project_paths, logdir, show_tokens, no_confirm)
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

