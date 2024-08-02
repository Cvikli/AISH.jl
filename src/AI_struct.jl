using Dates

struct Message
    timestamp::DateTime
    role::Symbol
    content::String
end

# AI State struct
@kwdef mutable struct AIState
    conversation::Dict{String, Vector{Message}}=Dict()
    conversation_sentences::Dict{String, String}=Dict()
    selected_conv_id::String=""
    model::String=""
end

# Initialize AI State
function initialize_ai_state(MODEL = "claude-3-5-sonnet-20240620")
    conversation_sentences = get_all_conversations_with_sentences()
    conversations = Dict(kid=>Message[] for kid in keys(conversation_sentences))
    state = AIState(conversations,
        conversation_sentences,
        "",
        MODEL,
    )
    generate_new_conversation(state)
    println("\e[32mAI State initialized successfully.\e[0m")  # Green text
    return state
end

cur_conv(state::AIState) = state.conversation[state.selected_conv_id]

limit_user_messages(state::AIState) = (c = cur_conv(state); length(c) > 12 && (state.conversation[state.selected_conv_id] = [c[1], c[4:end]...]))

system_prompt(state::AIState) = state.conversation[state.selected_conv_id][1]

function generate_new_conversation(state::AIState)
    new_id = generate_conversation_id()
    state.selected_conv_id = new_id
    state.conversation[new_id] = [Message(now(), :system, SYSTEM_PROMPT())]
    state.conversation_sentences[new_id] = ""
end

# Update system prompt
function update_system_prompt!(state::AIState)
    new_system_prompt = SYSTEM_PROMPT()
    cur_conv(state)[1] = Message(now(), :system, new_system_prompt)
    save_system_message(state, new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

# Add user message to conversation
function add_user_message!(state::AIState, user_message)
    push!(cur_conv(state), Message(now(), :user, strip(user_message)))
    save_user_message(state, user_message)
end

function add_ai_message!(state::AIState, ai_message)
    push!(cur_conv(state), Message(now(), :ai, strip(ai_message)))
    save_ai_message(state, ai_message)
end

function conversation_to_dict(state::AIState)
    result = []
    for message in cur_conv(state)
        push!(result, Dict(
            "timestamp" => Dates.format(message.timestamp, "yyyy-mm-dd_HH:MM:SS"),
            "role" => string(message.role),
            "message" => message.content
        ))
    end
    return result
end

# New function to get the filename for a specific conversation ID
function get_conversation_filename(conversation_id)
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    return isempty(files) ? nothing : joinpath(conversation_dir, sort(files)[end])
end
