const DEV_PACKAGES = [
    "AISH.jl",
    "EasyContext.jl",
    "EasyRAGStore.jl",
    "LLMRateLimiters.jl",
    "StreamCallbacksExt.jl"
]
function is_dev_package_path(paths::Vector{<:AbstractString})
    any(p -> basename(rstrip(expanduser(p), '/')) in DEV_PACKAGES, paths)
end

function set_revise_for_dev!(paths::Vector{<:AbstractString})
    if is_dev_package_path(paths)
        ENV["JULIA_REVISE"] = "manual"
        return true
    end
    return false
end
# Command handlers
function handle_project_switch(flow, args)
    paths = split(args)
    set_revise_for_dev!(paths)
    invalid_paths = filter(p -> !isdir(expanduser(p)), paths)
    if !isempty(invalid_paths)
        println("\nError: Following paths don't exist:")
        foreach(p -> println("  - $p"), invalid_paths)
    end
    update_workspace!(flow, paths)
    println("\nSwitched to projects: ", join(paths, ", "))
end

function handle_revise(flow, args)
    try
        @eval Main using Revise
        @eval Main Revise.revise()
        println("\nRevise: Code changes have been applied!")
    catch e
        println("\nError running Revise: ", e)
    end
end

function handle_editor_switch(flow, args)
    !set_editor(strip(args)) && return
    println("\nSwitched to editor: ", strip(args))
end

function handle_model_switch(flow, args)
    update_model!(flow, strip(args))
    println("\nSwitched to model: ", strip(args))
end

function handle_confirmation_toggle(flow, _)
    toggle_confirm!(flow)
    println("\nConfirmation ", flow.no_confirm ? "disabled" : "enabled")
end

function handle_julia_context(flow, _)
    flow isa STDFlow && (flow.use_julia = !flow.use_julia)
    println("\nJulia package context ", flow isa STDFlow && flow.use_julia ? "enabled" : "disabled")
end

function handle_reset(flow, args)
    if !isempty(strip(args))
        println("\nError: --reset doesn't accept additional arguments")
        return
    end
    reset_flow!(flow)
    println("\nReset conversation and context state while maintaining current settings")
end

function handle_planner(flow, args)
    flow isa STDFlow || return
    model = strip(args)
    valid_models = ["oro1", "oro1m", "gpt4", "claude", "gemexp", "o3m"]
    if !isempty(model)
        if !(model in valid_models)
            println("\nUnrecognized model, but might work: ", join(valid_models, ", "))
        end
        flow.planner.model = model
        flow.planner.enabled = true
        println("\nPlanner mode enabled with $model model")
        return
    end
    flow.planner.enabled && (flow.planner.model = "oro1m")
    toggle_planner!(flow)
    println("\nPlanner mode ", flow.planner.enabled ? "enabled" : "disabled",
    flow.planner.enabled ? " with $(flow.planner.model) model" : "")
end

function handle_status(flow, args)
    !isempty(strip(args)) && println("\nError: --status doesn't accept additional arguments")
    
    println("\nAISH Status:")
    println("  Model:     ", flow.agent.model)
    println("  Projects:  ", join(map(p -> abspath(expanduser(p)), flow.workspace_context.workspace.project_paths), "\n            "))
    if flow isa STDFlow
        println("  Planner:   ", flow.planner.enabled ? "enabled ($(flow.planner.model))" : "disabled")
        println("  Thinking:  ", isnothing(flow.thinking) ? "disabled" : "enabled ($(flow.thinking) tokens)")
    end
    println("  Editor:    ", get(ENV, "EDITOR", "default"))
end


function print_help()
    println("\nAvailable commands:")
    # Sort by command name but show primary commands first (not aliases)
    primary_cmds = filter(kv -> !any(c -> c != kv[1] && kv[2][2] === COMMANDS[c][2], keys(COMMANDS)), COMMANDS)
    for (cmd, (desc, _)) in sort(collect(primary_cmds))
        arg_hint = if cmd == "-p" "path1 path2"
                  elseif cmd == "--model" "name"
                  elseif cmd == "--editor" || cmd == "-e" "name[:port]"
                  elseif cmd == "--revise" || cmd == "-r" ""
                  elseif cmd == "--plan" "model"
                  elseif cmd == "--status" ""
                  else ""
                  end
        padding = arg_hint == "" ? "" : " "
        aliases = join([k for (k,v) in COMMANDS if k != cmd && v[2] === COMMANDS[cmd][2]], ", ")
        alias_str = isempty(aliases) ? "" : " (aliases: $aliases)"
        println("  $cmd$padding$arg_hint    : $desc$alias_str")
    end
end

# Add a new command handler for thinking
function handle_thinking(flow, args)
    if isempty(strip(args))
        # Toggle thinking off if it was on
        if hasfield(typeof(flow), :thinking) && !isnothing(flow.thinking)
            flow.thinking = nothing
            println("\nThinking mode disabled")
        else
            # Default to 8000 tokens if no value specified
            flow.thinking = 9000
            println("\nThinking mode enabled with default budget of 9000 tokens")
        end
        return
    end
    
    # Try to parse the argument as an integer
    try
        budget = parse(Int, strip(args))
        if budget <= 0
            flow.thinking = nothing
            println("\nThinking mode disabled")
        else
            flow.thinking = budget
            println("\nThinking mode enabled with budget of $budget tokens")
        end
    catch
        println("\nError: Thinking budget must be a positive integer")
    end
end

# Add to COMMANDS dictionary
const COMMANDS = Dict{String, Tuple{String, Function}}(
    "-p"       => ("Switch projects", handle_project_switch),
    "--revise" => ("Run Revise.revise()", handle_revise),
    "--editor" => ("Switch editor", handle_editor_switch),
    "--model"  => ("Switch model (e.g. claude, gpt4)", handle_model_switch),
    "-y"       => ("Toggle confirmation", handle_confirmation_toggle),
    "-jl"      => ("Toggle Julia package context", handle_julia_context),
    "--reset"  => ("Reset conversation and context", handle_reset),
    "--plan"   => ("Toggle planner mode, models: [oro1, oro1m, gpt4, claude, gemexp, o3m, ]", handle_planner),
    "--status" => ("Show current AISH status", handle_status),
    "-t"       => ("Set thinking budget (tokens) or toggle thinking mode", handle_thinking)
)
# Add aliases
COMMANDS["-e"] = (COMMANDS["--editor"][1], COMMANDS["--editor"][2])
COMMANDS["--jl"] = (COMMANDS["-jl"][1], COMMANDS["-jl"][2])
COMMANDS["-j"] = (COMMANDS["-jl"][1], COMMANDS["-jl"][2])
COMMANDS["-r"] = (COMMANDS["--revise"][1], COMMANDS["--revise"][2])  # Add revise alias
COMMANDS["-s"] = (COMMANDS["--status"][1], COMMANDS["--status"][2])  # Add status alias
COMMANDS["--think"] = (COMMANDS["-t"][1], COMMANDS["-t"][2])  # Add thinking alias
COMMANDS["-m"] = (COMMANDS["--model"][1], COMMANDS["--model"][2])  # Add model alias
COMMANDS["--help"] = ("Show help message", (_, _) -> print_help())
COMMANDS["-h"] = (COMMANDS["--help"][1], COMMANDS["--help"][2])



function handle_planner_toggle(flow, _)
	flow isa STDFlow || return
	toggle_planner!(flow)
	println("\nPlanner mode ", flow.planner.enabled ? "enabled" : "disabled")
    return :ignore
end

function handle_julia_context_toggle(flow, _)
	flow isa STDFlow && (flow.use_julia = !flow.use_julia)
	println("\nJulia package context ", flow isa STDFlow && flow.use_julia ? "enabled" : "disabled")
    return :ignore
end

function handle_editor_shortcut(flow, _)
	println("\nCtrl+E pressed. This should print!")
    return :ignore
end
    
ai_keymap = Dict(
    '\x11' => (s::MIState, o...) -> handle_planner_toggle(flow, ""),
    '\x0f' => (s::MIState, o...) -> handle_julia_context_toggle(flow, ""),
    '\x05' => (s::MIState, o...) -> handle_editor_shortcut(flow, "")
)