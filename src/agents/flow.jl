
# To automatically start in airepl(): julia --banner=no -i -e 'using AISH; AISH.airepl(auto_switch=true)'
function repl_init_flow(;workflow::DataType=STDFlow, project_paths=String["."], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true, tools=DEFAULT_TOOLS)
    flow = workflow(project_paths; logdir, show_tokens, silent, no_confirm, detached_git_dev, tools)
    set_terminal_title("AISH $(basename(rstrip(flow.workspace_context.workspace.root_path, '/')))")
    set_editor("meld_pro")
    return flow
end

function repl_run_flow(flow, cmd)
    println("\nProcessing your request...")
    try
        run(flow, cmd)
    catch e
        if e isa InterruptException
            println("\nOperation interrupted. Normalizing conversation state...")
            flow isa STDFlow && normalize_conversation!(flow)
            return
        end
        rethrow(e)
    end
end

function readline_init_flow(;workflow::DataType, resume_data=nothing, project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false, tools=DEFAULT_TOOLS)
    !silent && greet(ChatSH)
    flow = isnothing(resume_data) ? workflow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev, use_julia, verbose=!silent, tools) : workflow(resume_data)
    
    nice_exit_handler(flow.conv_ctx)
    set_terminal_title("AISH $(basename(rstrip(flow.workspace_context.workspace.root_path, '/')))")
  
    !silent && isempty(user_question) && (isdefined(Base, :active_repl) ? println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ") : println("Your multiline input (empty line to finish):"))
    return flow
end
function readline_run_flow(flow, cmd)
    println("\nProcessing your request...")
    try
        result = run(flow, cmd)
        result == :MERGE && isdefined(flow, :version_control) && !isnothing(flow.version_control) && merge_git(flow.version_control)
    catch e
        if e isa InterruptException
            println("\nOperation interrupted. Normalizing conversation state...")
            flow isa STDFlow && normalize_conversation!(flow)
            return
        end
        rethrow(e)
    end
end
