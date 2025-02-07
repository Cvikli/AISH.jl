
# To automatically start in airepl(): julia --banner=no -i -e 'using AISH; AISH.airepl(auto_switch=true)'

init_flow(::Val{:SIMPLE}, workflow::DataType=STDFlow; project_paths::Vector{String}=String["."], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true) = init_flow(workflow; project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev)
init_flow(workflow::DataType; project_paths::Vector{String}, logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true) = begin
    flow = workflow(project_paths; logdir, show_tokens, silent, no_confirm, detached_git_dev)
    set_editor("meld_pro")
    return flow
end

init_flow(::Val{:STANDARD}, workflow::DataType; project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false) = readline_init_flow(;workflow, project_paths, logdir, show_tokens, silent, no_confirm, loop, detached_git_dev, use_julia)
readline_init_flow(workflow::DataType; project_paths, logdir, show_tokens, silent, no_confirm=false, loop=true, detached_git_dev=true, use_julia=false) = begin
    !silent && greet(ChatSH)
    flow = workflow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev, use_julia, verbose=!silent)
    
    nice_exit_handler(flow.conv_ctx)
  
    !silent && isempty(user_question) && (isdefined(Base, :active_repl) ? println("Your first [Enter] will just interrupt the REPL line and get into the conversation after that: ") : println("Your multiline input (empty line to finish):"))
    return flow
end

run_flow!(::Val{:STANDARD}, workflow::Workflow; user_question::AbstractString) = run_flow!(workflow, user_question)
run_flow!(flow::Workflow, user_question::AbstractString) = begin
    println("Thinking...")
    try
        run(flow, user_question)
    catch e
        if e isa InterruptException
            println("\nOperation interrupted. Normalizing conversation state...")
            flow isa STDFlow && normalize_conversation!(flow)
        else
            rethrow(e)
        end
    end
end

run_flow!(::Val{:VERSION_CONTROL}, workflow::Workflow; user_question) = run_flow_version_control!(workflow, user_question)
run_flow_version_control!(flow, cmd) = begin
    println("Thinking...")
    try
        result = run(flow, cmd)
        result == :MERGE && isdefined(flow, :version_control) && !isnothing(flow.version_control) && merge_git(flow.version_control)
    catch e
        if e isa InterruptException
            println("\nOperation interrupted. Normalizing conversation state...")
        else
            rethrow(e)
        end
    end
end
run_flow!(::Val{:NICE_EXIT}, workflow::Workflow; user_question) = run_flow_interruptible(workflow, user_question)
run_flow_interruptible!(flow, user_question) = begin
	try
		_in_loop[] = true
		run(flow, user_question)
		_in_loop[] = false
	catch e
		if e isa InterruptException
			println("\nLoop interrupted. Continueing...")
		else
			rethrow(e)
		end
	end
end