using REPL
using ReplMaker
using REPL.LineEdit: MIState, PromptState, default_keymap, escape_defaults
using Base.Filesystem
using Base: AnyDict, basename, rstrip
using EasyContext: set_editor

include("repl_arg_parser.jl")
include("repl_handler.jl")

# interface required functions.
get_flags_str(::Workflow) = " [unimplemented]"  # Base case for generic workflows
reset_flow!(::Workflow)   = @warn "Unimplemented."

@kwdef mutable struct PathCompletionProvider <: REPL.LineEdit.CompletionProvider
    modifiers::REPL.LineEdit.Modifiers=REPL.LineEdit.Modifiers()
end

REPL.LineEdit.setmodifiers!(c::PathCompletionProvider, m::REPL.LineEdit.Modifiers) = c.modifiers = m
REPL.LineEdit.complete_line(c::PathCompletionProvider, s::REPL.LineEdit.PromptState; kwargs...) = begin
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
                if isdir(joinpath(dir, entry)) && startswith(entry, base)  # Case-insensitive comparison
                    # Use normpath to handle ".." properly
                    rel_path = isempty(dirname(current)) ? entry : joinpath(dirname(current), entry)
                    push!(completions, normpath(rel_path) * "/")
                end
            end
            # completions = [t[length(dir)+2:end] for t in completions]
            return completions, String(current), !isempty(completions)
        end
    end
    return String[], "", false
end



function repl_parser(user_question::AbstractString, flow::Workflow)
    cmd = strip(user_question)
    isempty(cmd) && return

    # Handle command or process as regular input
    for (prefix, (_, handler)) in COMMANDS
        if startswith(cmd, prefix * " ") || cmd == prefix
            handler(flow, strip(cmd[length(prefix)+1:end]))
            return  # Return immediately after handling command
        end
    end

    # Handle unknown commands starting with --
    if startswith(cmd, "--")
        println("\nError: Unknown command '", cmd, "'")
        println("Use --help or -h to see available commands")
        return
    end

    run_flow!(flow, cmd)
    return
end

global_flow = nothing 
function create_ai_repl(flow::Workflow)
    global global_flow = flow  # Just to make it accessible.
    
    parser(input) = repl_parser(input, flow)
    initrepl(
        parser;
        prompt_text=() -> "AISH$(get_flags_str(flow))> ",
        prompt_color=:cyan,
        start_key=')',
        mode_name=:ai,
        repl=Base.active_repl,
        valid_input_checker=Returns(true),
        completion_provider=PathCompletionProvider(),
        # keymap=REPL.LineEdit.keymap([ai_keymap, default_keymap, escape_defaults]),
        # keymap=ai_keymap,
        sticky_mode=false
    )
end

function initialize_aish_mode(flow, auto_switch, initial_message="")
    set_revise_for_dev!([pwd()])  # Check current directory as single-element array

    ai_mode = create_ai_repl(flow)
    print_help()

    @async_showerr if auto_switch # without @async the .mistate is nothing...
        for _ in 1:50
            isdefined(Base, :active_repl) && isdefined(Base.active_repl, :mistate) && !isnothing(Base.active_repl.mistate) && break
            sleep(0.01)
        end
        
        !isdefined(Base, :active_repl) && return println("Failed to enter REPL after 1 second.")
    
        println("Switching to AISH mode automatically.")
        ReplMaker.enter_mode!(Base.active_repl.mistate, ai_mode)
        
        # Process initial message if provided
        !isempty(initial_message) && ai_parser(initial_message, flow)
    end
end

function airepl_noargs(;initial_message, project_paths=String["."], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true, auto_switch=true, tools=DEFAULT_TOOLS)
    flow = init_flow(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev, tools)

    isdefined(Base, :active_repl) && return initialize_aish_mode(flow, auto_switch, initial_message)
    atreplinit(repl -> initialize_aish_mode(flow, auto_switch, initial_message))
end

function airepl(;initial_message=nothing, project_paths=String["."], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true, auto_switch=true, tools=DEFAULT_TOOLS)
    isnothing(initial_message) && (initial_message = parse_repl_args())
    airepl_noargs(;initial_message, project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev, auto_switch, tools)
end
