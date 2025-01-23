include("readline_arg_parser.jl")

function start_conversation(user_question=""; workflow::DataType, resume_data=nothing, project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false, tools=DEFAULT_TOOLS)
  flow = readline_init_flow(;workflow, resume_data, project_paths, logdir, show_tokens, silent, no_confirm, loop, detached_git_dev, use_julia, tools)
  set_terminal_title("$(PROGRAM_NAME) $(basename(rstrip(flow.workspace_context.workspace.root_path, '/')))")

  while loop || !isempty(user_question)
    user_question = isempty(user_question) ? wait_user_question(user_question) : user_question
    !silent && println("Thinking...")  # Only print if not silent
    readline_run_flow(flow, user_question)

    user_question = ""
  end
end
start(message; workflow::DataType, resume_data=nothing, project_paths::String="", kwargs...) = start(message; workflow, resume_data, project_paths=[project_paths], kwargs...)
start(message; workflow::DataType, resume_data=nothing, project_paths::Vector{String}=String[], logdir=LOGDIR, show_tokens=false, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false, tools=DEFAULT_TOOLS) = start_conversation(message; workflow, loop, resume_data, project_paths, logdir, show_tokens, silent=!isempty(message), no_confirm, detached_git_dev, use_julia, tools)

function main(;workflow::DataType, tools=DEFAULT_TOOLS, loop=true)
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
        tools
  )
end
julia_main(;workflow::DataType, loop=true) = main(;workflow, loop)

export main, julia_main