using JLD2
using JSON3
using SHA
using Dates

@kwdef mutable struct PersistableWorkFlowSettings
    version::VersionNumber = v"1.0.0"
    workflow

    timestamp::DateTime = now(UTC)
    conv_ctx::ConversationX 
    question_acc::QuestionCTX
    julia_CTX::JuliaCTX
    workspace_CTX::WorkspaceCTX
    version_control::Union{GitTracker,Nothing}
    # workspace_paths::Vector{String}
    # ignore...
    git_paths::Vector{String}

    
    logdir::String
    config::Dict{String,Any} = Dict{String,Any}(
        "detached_git_dev" => false,  # Renamed here
        # resume=args["resume"], 
        "silent" => false,
        "loop" => false,
        "show_tokens" => false,
        "no_confirm" => false,
        "compression" => true,
        "checksum" => true
    )
end

# f <- c (load state + other clients interactions)
# f -> c (user interaction + ai interaction)
# f -> b (user_interaction)
# f <- b (ai_interaction)

