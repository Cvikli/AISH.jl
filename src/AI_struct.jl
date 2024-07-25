using PromptingTools: SystemMessage, UserMessage, AbstractChatMessage

# AI State struct
mutable struct AIState
    conversation::Vector{PromptingTools.AbstractChatMessage}
    model::String
end

# Initialize AI State
function initialize_ai_state(MODEL = "claude")
    system_prompt = SYSTEM_PROMPT(PROJECT_PATH)
    state = AIState(
        [SystemMessage(system_prompt)],
        MODEL,
    )
    println("\e[32mAI State initialized successfully.\e[0m")  # Green text
    return state
end

# Update system prompt
function update_system_prompt!(state::AIState)
    new_system_prompt = SYSTEM_PROMPT(PROJECT_PATH)
    state.conversation[1] = SystemMessage(new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end
