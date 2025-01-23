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
    valid_models = ["oro1", "oro1m", "gpt4", "claude", "gemexp", "tqwen25b72"]
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


function print_help()
    println("\nAvailable commands:")
    # Sort by command name but show primary commands first (not aliases)
    primary_cmds = filter(kv -> !any(c -> c != kv[1] && kv[2][2] === COMMANDS[c][2], keys(COMMANDS)), COMMANDS)
    for (cmd, (desc, _)) in sort(collect(primary_cmds))
        arg_hint = if cmd == "-p" "path1 path2"
                  elseif cmd == "--model" "name"
                  elseif cmd == "--editor" || cmd == "-e" "name[:port]"
                  elseif cmd == "--revise" || cmd == "-r" ""
                  else ""
                  end
        padding = arg_hint == "" ? "" : " "
        println("  $cmd$padding$arg_hint    : $desc")
    end
end

const COMMANDS = Dict{String, Tuple{String, Function}}(
    "-p"       => ("Switch projects", handle_project_switch),
    "--revise" => ("Run Revise.revise()", handle_revise),
    "--editor" => ("Switch editor", handle_editor_switch),
    "--model"  => ("Switch model (e.g. claude, gpt4)", handle_model_switch),
    "-y"       => ("Toggle confirmation", handle_confirmation_toggle),
    "-jl"      => ("Toggle Julia package context", handle_julia_context),
    "--reset"  => ("Reset conversation and context", handle_reset),
    "--plan"   => ("Toggle planner mode, models: [oro1, oro1m, gpt4, claude, gemexp, tqwen25b72, ]", handle_planner)
)
# Add aliases
COMMANDS["-e"] = (COMMANDS["--editor"][1], COMMANDS["--editor"][2])
COMMANDS["--jl"] = (COMMANDS["-jl"][1], COMMANDS["-jl"][2])
COMMANDS["-j"] = (COMMANDS["-jl"][1], COMMANDS["-jl"][2])
COMMANDS["-r"] = (COMMANDS["--revise"][1], COMMANDS["--revise"][2])  # Add revise alias
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