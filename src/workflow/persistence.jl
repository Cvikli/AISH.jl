using JLD2
using JSON3
using SHA
using Dates

@kwdef mutable struct PersistableWorkFlowSettings
    version::VersionNumber = v"1.0.0"
    timestamp::DateTime = now(UTC)
    conv_ctx::ConversationX 
    workspace_paths::Vector{String}
    question_acc::QuestionCTX
    LLM_reflection::String
    git_paths::Vector{String}
    persist_path::String
    config::Dict{String,Any} = Dict{String,Any}(
        "show_tokens" => false,
        "no_confirm" => false,
        "age_tracker_history" => 10,
        "age_tracker_cut" => 4,
        "format" => "jld2",  # or "json"
        "compression" => true,
        "checksum" => true
    )
end

f -> c
f -> b
f <- b

