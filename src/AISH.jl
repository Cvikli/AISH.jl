
module AISH

using BoilerplateCvikli: @async_showerr
using EasyContext: greet
using EasyContext: update_last_user_message_meta
using EasyContext: add_error_message!
using EasyContext: wait_user_question, reset!
using EasyContext: LLM_solve
using EasyContext: QuestionCTX
using EasyContext: print_project_tree
using EasyContext: context_combiner!
using EasyContext: LLM_reflect
using EasyContext: get_cache_setting
using EasyContext: shell_ctx_2_string
using EasyContext: init_workspace_context
using EasyContext: process_workspace_context
using EasyContext: process_julia_context
using EasyContext: cut_old_conversation_history!
using EasyContext: workspace_format_description, julia_format_guide
using EasyContext: last_msg
using EasyContext: Conversation, TestFramework, PersistableState
using EasyContext: merge_git
using EasyContext: Skill
using EasyContext: WorkspaceCTX, JuliaCTX
using EasyContext: Workflow
using EasyContext: execute
using EasyContext

include("utils.jl")
include("config.jl")
include("arg_parser.jl")

include("prompt.jl")
include("workflow/selfreflect_flow.jl")
include("workflow/std_flow.jl")
include("airepl.jl")

function start_conversation(user_question=""; workflow::DataType, resume_data=nothing, project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false, skills=DEFAULT_SKILLS)
  !silent && greet(ChatSH)
  model = isnothing(resume_data) ? workflow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev, use_julia, verbose=!silent, skills) : workflow(resume_data)
  
  nice_exit_handler(model.conv_ctx)
  set_terminal_title("AISH $(model.workspace_context.workspace.root_path)")

  !silent && isempty(user_question) && (isdefined(Base, :active_repl) ? println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ") : println("Your multiline input (empty line to finish):"))

  while loop || !isempty(user_question)
    user_question = isempty(user_question) ? wait_user_question(user_question) : user_question
    !silent && println("Thinking...")  # Only print if not silent
    
    try
      _in_loop[] = true
      result = model(user_question)
      result == :MERGE && isdefined(model, :version_control) && !isnothing(model.version_control) && merge_git(model.version_control)
      _in_loop[] = false
    catch e
      if e isa InterruptException
        println("\nSelf-reflection loop interrupted. Continuing...")
      else
        @show e
        rethrow(e)
      end
    end

    user_question = ""
  end
end
function start(message=""; workflow::DataType, resume_data=nothing, project_paths::Union{String,Vector{String}}=String[], logdir=LOGDIR, show_tokens=false, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false, skills=DEFAULT_SKILLS)
  isa(project_paths, String) && (project_paths = [project_paths])
  start_conversation(message; workflow, loop, resume_data, project_paths, logdir, show_tokens, silent=!isempty(message), no_confirm, detached_git_dev, use_julia, skills)
end

function main(;workflow::DataType, skills=DEFAULT_SKILLS, loop=true)
  args = parse_commandline()
  msg  = args["message"]
  start(msg; 
        workflow,   
        resume_data=nothing,
        project_paths=args["project-paths"], 
        show_tokens=args["tokens"], 
        logdir=args["log-dir"], 
        loop=!args["no-loop"] && loop, 
        no_confirm=args["no-confirm"],
        detached_git_dev=args["git"],
        use_julia=args["julia"],
        skills
  )
end
julia_main(;workflow::DataType, loop=true) = main(;workflow, loop)

export main, julia_main

# include("precompile_scripts.jl")

end # module AISH
