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

const COMMANDS = Dict{String, Tuple{String, Function}}(
    "-p"       => ("Switch projects", (flow, args) -> begin
        paths = split(args)
        invalid_paths = filter(p -> !isdir(expanduser(p)), paths)
        if !isempty(invalid_paths)
            println("\nError: Following paths don't exist:")
            foreach(p -> println("  - $p"), invalid_paths)
        end
        update_workspace!(flow, paths)
        println("\nSwitched to projects: ", join(paths, ", "))
    end),
    "--editor" => ("Switch editor", (flow, args) -> begin
        !set_editor(strip(args)) && return
        println("\nSwitched to editor: ", strip(args))
    end),
    "--model"  => ("Switch model (e.g. claude, gpt4)", (flow, args) -> begin
        update_model!(flow, strip(args))
        println("\nSwitched to model: ", strip(args))
    end),
    "-y"       => ("Toggle confirmation", (flow, _) -> begin
        toggle_confirm!(flow)
        println("\nConfirmation ", flow.no_confirm ? "disabled" : "enabled")
    end),
    "-jl"      => ("Toggle Julia package context", (flow, _) -> begin
        flow isa STDFlow && (flow.use_julia = !flow.use_julia)
        println("\nJulia package context ", flow isa STDFlow && flow.use_julia ? "enabled" : "disabled")
    end),
    "--reset"  => ("Reset conversation and context", (flow, args) -> begin
        if !isempty(strip(args))
            println("\nError: --reset doesn't accept additional arguments")
            return
        end
        reset_flow!(flow)
        println("\nReset conversation and context state while maintaining current settings")
    end),
    "--plan"   => ("Toggle planner mode, model option: [oro1, \$]", (flow, args) -> begin
        flow isa STDFlow || return
        if args == "\$" || args == "oro1"
            flow.planner.model = "oro1"
            flow.use_planner = true
            println("\nPlanner mode enabled with oro1 model")
        else
            flow.use_planner && (flow.planner.model = "oro1m")  # Switch back to cheaper model when toggling
            toggle_planner!(flow)
            println("\nPlanner mode ", flow.use_planner ? "enabled" : "disabled", 
                    flow.use_planner ? " with $(flow.planner.model) model" : "")
        end
    end)
)

# Add aliases
COMMANDS["-e"] = (COMMANDS["--editor"][1], COMMANDS["--editor"][2])
COMMANDS["--jl"] = (COMMANDS["-jl"][1], COMMANDS["-jl"][2])
COMMANDS["-j"] = (COMMANDS["-jl"][1], COMMANDS["-jl"][2])
COMMANDS["--help"] = ("Show help message", (_, _) -> print_help())
COMMANDS["-h"] = (COMMANDS["--help"][1], COMMANDS["--help"][2])

function print_help()
    println("\nAvailable commands:")
    # Sort by command name but show primary commands first (not aliases)
    primary_cmds = filter(kv -> !any(c -> c != kv[1] && kv[2][2] === COMMANDS[c][2], keys(COMMANDS)), COMMANDS)
    for (cmd, (desc, _)) in sort(collect(primary_cmds))
        arg_hint = if cmd == "-p" "path1 path2"
                  elseif cmd == "--model" "name"
                  elseif cmd == "--editor" || cmd == "-e" "name[:port]"
                  else ""
                  end
        padding = arg_hint == "" ? "" : " "
        println("  $cmd$padding$arg_hint    : $desc")
    end
end

function ai_parser(user_question::AbstractString, flow::Workflow)
    cmd = strip(user_question)
    isempty(cmd) && return

    # Handle command or process as regular input
    for (prefix, (_, handler)) in COMMANDS
        if startswith(cmd, prefix * " ") || cmd == prefix
            handler(flow, strip(cmd[length(prefix)+1:end]))
            # Special case for --plan as it can be combined
            prefix == "--plan" && !isempty(strip(cmd[7:end])) && ai_parser(strip(cmd[7:end]), flow)
            return
        end
    end
    
    # Handle unknown commands starting with --
    if startswith(cmd, "--")
        println("\nError: Unknown command '", cmd, "'")
        println("Use --help or -h to see available commands")
        return
    end

    # Process as regular input
    println("\nProcessing your request...")
    try
        run(flow, cmd)
        nothing
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
function airepl(;project_paths=String["."], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true, auto_switch=true, initial_message="", skills=DEFAULT_SKILLS)
    flow = STDFlow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev, skills)
    set_editor("meld_pro")  # Set default editor

    # If REPL is already active, initialize directly
    if isdefined(Base, :active_repl)
        initialize_aish_mode(flow, auto_switch, initial_message)
        return
    end

    # Use atreplinit for initialization when REPL starts
    atreplinit() do repl
        initialize_aish_mode(flow, auto_switch, initial_message)
    end
end

function initialize_aish_mode(flow, auto_switch, initial_message="")
    ai_mode = create_ai_repl(flow)
    println("AI REPL mode initialized. Press ')' to enter and backspace to exit.")
    print_help()

    @async if auto_switch # without @async the .mistate is nothing...
        try
            for _ in 1:50
                isdefined(Base, :active_repl) && isdefined(Base.active_repl, :mistate) && !isnothing(Base.active_repl.mistate) && break
                sleep(0.01)
            end
            
            if !isdefined(Base, :active_repl)
                println("Failed to enter REPL after 1 second.")
                return
            end
        
            println("Switching to AISH mode automatically.")
            ReplMaker.enter_mode!(Base.active_repl.mistate, ai_mode)
            
            # Process initial message if provided
            !isempty(initial_message) && ai_parser(initial_message, flow)
        catch e
            @warn "Failed to switch to AISH mode automatically." exception=e
        end
    end
end
