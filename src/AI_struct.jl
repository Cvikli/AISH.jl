using PromptingTools: AbstractChatMessage

# AI State struct
@kwdef mutable struct AIState
    conversation::Dict{String, Vector{AbstractChatMessage}}=Dict()
    selected_conv_id::String=""
    model::String=""
end

# Initialize AI State
function initialize_ai_state(MODEL = "claude-3-5-sonnet-20240620")
    system_prompt = SYSTEM_PROMPT()

    conversations = Dict(get_id_from_file(kid)=>AbstractChatMessage[] for kid in get_all_conversations_file())
    new_id = generate_conversation_id()
    conversations[new_id]=AbstractChatMessage[SystemMessage(system_prompt)]
    state = AIState(conversations,
        new_id,
        MODEL,
    )
    println("\e[32mAI State initialized successfully.\e[0m")  # Green text
    return state
end

cur_conv(state::AIState) = state.conversation[state.selected_conv_id]

limit_user_messages(state::AIState) = (c = cur_conv(state); length(c) > 12 && (state.conversation[state.selected_conv_id] = [c[1], c[4:end]...]))

generate_new_conversation(ai_state) = begin
    new_id = generate_conversation_id()
    ai_state.selected_conv_id = new_id
    ai_state.conversation[new_id] = AbstractChatMessage[SystemMessage(SYSTEM_PROMPT())]
end

# Update system prompt
function update_system_prompt!(state::AIState)
    new_system_prompt = SYSTEM_PROMPT()
    cur_conv(state)[1] = SystemMessage(new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

# Add user message to conversation
function add_user_message!(state::AIState, user_message; save_message::Bool=true)
    push!(cur_conv(state), UserMessage(strip(user_message)))
    save_message && save_user_message(state.selected_conv_id, user_message)
end

function conversation_to_dict(state::AIState)
    result = []
    for message in cur_conv(state)
        role = message isa SystemMessage ? "system" :
               message isa UserMessage ? "user" :
               message isa AIMessage ? "ai" : "unknown"
        
        push!(result, Dict(
            "timestamp" => Dates.format(now(), "yyyy-mm-dd_HH:MM:SS"),
            "role" => role,
            "message" => message.content
        ))
    end
    return result
end

