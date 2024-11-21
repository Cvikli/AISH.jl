using REPL
using ReplMaker
using REPL.LineEdit
using Base.Filesystem
using Base: AnyDict

mutable struct PathCompletionProvider <: REPL.LineEdit.CompletionProvider
    modifiers::REPL.LineEdit.Modifiers
    PathCompletionProvider() = new(REPL.LineEdit.Modifiers())
end

function REPL.LineEdit.complete_line(c::PathCompletionProvider, s::REPL.LineEdit.PromptState; kwargs...)
    partial = REPL.beforecursor(s.input_buffer)
    full = REPL.LineEdit.input_string(s)

    if startswith(partial, "-p ")
        # Get the partial path being typed
        parts = split(partial[4:end], ' ', keepempty=false)
        current = isempty(parts) ? "" : last(parts)
        
        # Expand user path if needed
        expanded_current = expanduser(current)
        dir = isempty(expanded_current) ? pwd() : dirname(expanded_current)
        base = basename(expanded_current)
        # base = String(current) #basename(expanded_current)
        
        # Get completions if directory exists
        if isdir(dir)
            completions = String[]
            for entry in readdir(dir)
                if isdir(joinpath(dir, entry)) && startswith(entry, base)
                    # Use normpath to handle ".." properly
                    completion_path = normpath(joinpath(dirname(current), entry))
                    push!(completions, completion_path * "/")
                end
            end
            # completions = [t[length(dir)+2:end] for t in completions]
            return completions, String(current), !isempty(completions)
        end
    end
    return String[], "", false
end

REPL.LineEdit.setmodifiers!(c::PathCompletionProvider, m::REPL.LineEdit.Modifiers) = c.modifiers = m

function ai_parser(user_question::String, flow::Workflow)
    cmd = strip(user_question)
    try
        if startswith(cmd, "-p ")
            paths = split(cmd[3:end])
            # Check if paths exist
            invalid_paths = filter(p -> !isdir(expanduser(p)), paths)
            if !isempty(invalid_paths)
                println("\nError: Following paths don't exist:")
                foreach(p -> println("  - $p"), invalid_paths)
            end
            update_workspace!(flow, paths)
            println("\nSwitched to projects: ", join(paths, ", "))
        elseif startswith(cmd, "--model ")
            new_model = strip(cmd[8:end])
            update_model!(flow, new_model)
            println("\nSwitched to model: ", new_model)
        elseif startswith(cmd, "-y")
            toggle_confirm!(flow)
            println("\nConfirmation ", flow.no_confirm ? "disabled" : "enabled")
        elseif !isempty(cmd)
            println("\nProcessing your request...")
            run(flow, user_question)
        end
    catch e
        if e isa InterruptException
            println("\nOperation interrupted. Normalizing conversation state...")
            flow isa STDFlow && normalize_conversation!(flow)
            return
        end
        rethrow(e)
    end
end
function create_ai_repl(flow::Workflow)
    parser(input) = ai_parser(input, flow)
    
    repl = Base.active_repl
    initrepl(
        parser;
        prompt_text=() -> "AISH> ",
        prompt_color=:cyan,
        start_key=')',
        mode_name=:ai,
        repl=repl,
        valid_input_checker=Returns(true),
        completion_provider=PathCompletionProvider(),
        sticky_mode=false
    )
end

start_std_repl(;kw...) = airepl(kw...)
function airepl(;project_paths=String[], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true)
    flow = STDFlow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev)
    EasyContext.CURRENT_EDITOR = MELD_PRO

    ai_mode = create_ai_repl(flow)
    println("AI REPL mode initialized. Press ')' to enter and backspace to exit.")
    println("Available commands:")
    println("  -p path1 path2    : Switch projects")
    println("  --model name      : Switch model (e.g. claude, gpt4)")
    println("  -y               : Toggle confirmation")
    ai_mode
end
