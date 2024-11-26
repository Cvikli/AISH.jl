using REPL
using ReplMaker
using REPL.LineEdit: MIState, PromptState, default_keymap, escape_defaults
using Base.Filesystem
using Base: AnyDict

# interface required functions.
get_flags_str(::Workflow) = " [unimplemented]"  # Base case for generic workflows
reset_flow!(::Workflow) = @warn "Unimplemented."

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

function parse_editor_command(cmd::String)
    # Strip the command prefix
    editor_setting = strip(startswith(cmd, "--editor") ? cmd[9:end] : cmd[3:end])
    
    # Use centralized get_editor with port handling
    editor_config = get_editor(editor_setting, nothing)
    if editor_config.editor === nothing
        return nothing, "Unknown editor. Available editors: $(join(keys(EDITOR_MAP), ", "))"
    end
    
    return editor_config, nothing
end

function ai_parser(user_question::String, flow::Workflow)
    cmd = strip(user_question)
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
    elseif startswith(cmd, "--editor ") || startswith(cmd, "-e ")
        editor_setting = strip(startswith(cmd, "--editor") ? cmd[9:end] : cmd[3:end])
        if !set_editor(editor_setting)
            return
        end
        println("\nSwitched to editor: ", editor_setting)
    elseif startswith(cmd, "--model ")
        new_model = strip(cmd[8:end])
        update_model!(flow, new_model)
        println("\nSwitched to model: ", new_model)
    elseif startswith(cmd, "-y")
        toggle_confirm!(flow)
        println("\nConfirmation ", flow.no_confirm ? "disabled" : "enabled")
    elseif startswith(cmd, "-jl")
        flow isa STDFlow && (flow.use_julia = !flow.use_julia)
        println("\nJulia package context ", flow isa STDFlow && flow.use_julia ? "enabled" : "disabled")
    elseif startswith(cmd, "--reset")
        if !isempty(strip(cmd[7:end]))
            println("\nError: --reset doesn't accept additional arguments")
            return
        end
        reset_flow!(flow)
        println("\nReset conversation and context state while maintaining current settings")
    else
        # Handle --plan flag if present, then process any remaining command
        if startswith(cmd, "--plan")
            flow isa STDFlow && toggle_planner!(flow)
            println("\nPlanner mode ", flow isa STDFlow && flow.use_planner ? "enabled" : "disabled")
            cmd = strip(cmd[7:end])  # Remove --plan and process remaining text
        end
        
        if !isempty(cmd)
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
    end
end

function create_ai_repl(flow::Workflow)
    parser(input) = ai_parser(input, flow)
    
    # Add flag toggle keymaps using Ctrl combinations
    ai_keymap = AnyDict(
        # Plan toggle (Ctrl-Q)
        "^Q" => (s::MIState,o...)->begin
            flow isa STDFlow && toggle_planner!(flow)
            println("\nPlanner mode ", flow isa STDFlow && flow.use_planner ? "enabled" : "disabled")
            return :ignore
        end,
        # Julia context toggle (Ctrl-O)
        "^O" => (s::MIState,o...)->begin
            flow isa STDFlow && (flow.use_julia = !flow.use_julia)
            println("\nJulia package context ", flow isa STDFlow && flow.use_julia ? "enabled" : "disabled")
            return :ignore
        end
    )
    
    repl = Base.active_repl
    initrepl(
        parser;
        prompt_text=() -> "AISH$(get_flags_str(flow))> ",
        prompt_color=:cyan,
        start_key=')',
        mode_name=:ai,
        repl=repl,
        valid_input_checker=Returns(true),
        completion_provider=PathCompletionProvider(),
        keymap=REPL.LineEdit.keymap([ai_keymap, default_keymap, escape_defaults]),
        sticky_mode=false
    )
end

start_std_repl(;kw...) = airepl(kw...)
# To automatically start in airepl(): julia --banner=no -i -e 'using AISH; AISH.airepl(auto_switch=true)'
function airepl(;project_paths=String["."], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true, auto_switch=false)
    flow = STDFlow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev)
    set_editor("meld_pro")  # Set default editor

    # If REPL is already active, initialize directly
    if isdefined(Base, :active_repl)
        initialize_aish_mode(flow, auto_switch)
        return
    end

    # Otherwise wait for REPL from an async task
    @async begin
        for _ in 1:100
            isdefined(Base, :active_repl) && break
            sleep(0.01)
        end
        
        if !isdefined(Base, :active_repl)
            println("Failed to initialize REPL after 1 second. AISH mode might not work properly.")
            return
        end
        
        initialize_aish_mode(flow, auto_switch)
    end
end

function initialize_aish_mode(flow, auto_switch)
    ai_mode = create_ai_repl(flow)
    println("AI REPL mode initialized. Press ')' to enter and backspace to exit.")
    println("Available commands:")
    println("  -p path1 path2    : Switch projects")
    println("  --model name      : Switch model (e.g. claude, gpt4)")
    println("  -e, --editor name[:port] : Switch editor ($(join(keys(EDITOR_MAP), ", "))[:port])")
    println("  -y               : Toggle confirmation")
    println("  -jl              : Toggle Julia package context")
    println("  --plan           : Toggle planner mode")
    println("  --reset          : Reset conversation and context")

    if auto_switch
        try
            println("Switching to AISH mode automatically.")
            ReplMaker.enter_mode!(ai_mode)
        catch e
            @warn "Failed to switch to AISH mode automatically." exception=e
        end
    end
end
