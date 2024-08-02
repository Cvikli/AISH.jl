using PromptingTools: AbstractChatMessage
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
    system_prompt = SYSTEM_PROMPT()

    conversations = Dict(get_id_from_file(kid)=>Message[] for kid in get_all_conversations_file())
    new_id = generate_conversation_id()
    conversations[new_id]=[Message(now(), :system, system_prompt)]
    
    conversation_sentences = get_all_conversations_with_sentences()
    
    state = AIState(conversations,
        new_id,
        MODEL,
        conversation_sentences
    )
    println("\e[32mAI State initialized successfully.\e[0m")  # Green text
    return state
end

cur_conv(state::AIState) = state.conversation[state.selected_conv_id]

limit_user_messages(state::AIState) = (c = cur_conv(state); length(c) > 12 && (state.conversation[state.selected_conv_id] = [c[1], c[4:end]...]))

generate_new_conversation(ai_state) = begin
    new_id = generate_conversation_id()
    ai_state.selected_conv_id = new_id
    ai_state.conversation[new_id] = [Message(now(), :system, SYSTEM_PROMPT())]
end

# Update system prompt
function update_system_prompt!(state::AIState)
    new_system_prompt = SYSTEM_PROMPT()
    cur_conv(state)[1] = Message(now(), :system, new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

# Add user message to conversation
function add_user_message!(state::AIState, user_message; save_message::Bool=true)
    push!(cur_conv(state), Message(now(), :user, strip(user_message)))
    if save_message
        save_user_message(state.selected_conv_id, user_message)
        update_conversation_sentence!(state, state.selected_conv_id)
    end
end

function update_conversation_sentence!(state::AIState, conversation_id)
    filename = get_conversation_filename(conversation_id)
    if !isnothing(filename)
        state.conversation_sentences[conversation_id] = get_conversation_first_sentence(filename)
    end
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
    return isempty(files) ? nothing : sort(files)[end]
end
