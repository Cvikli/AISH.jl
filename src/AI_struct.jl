using PromptingTools: SystemMessage, UserMessage, AbstractChatMessage

# AI State struct
mutable struct AIState
    conversation::Vector{PromptingTools.AbstractChatMessage}
    model::String
end

# Initialize AI State
function initialize_ai_state(MODEL = "claude-3-5-sonnet-20240620")
    system_prompt = SYSTEM_PROMPT()
    state = AIState(
        [SystemMessage(system_prompt)],
        MODEL,
    )
    println("\e[32mAI State initialized successfully.\e[0m")  # Green text
    return state
end

# Update system prompt
function update_system_prompt!(state::AIState)
    new_system_prompt = SYSTEM_PROMPT()
    state.conversation[1] = SystemMessage(new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

# Add user message to conversation
function add_user_message!(state::AIState, user_message; save_message::Bool=true)
    push!(state.conversation, UserMessage(strip(user_message)))
    save_message && save_user_message(user_message)
end

