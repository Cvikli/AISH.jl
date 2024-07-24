using PromptingTools: SystemMessage, UserMessage, AbstractChatMessage

# AI State struct
mutable struct AIState
    conversation::Vector{PromptingTools.AbstractChatMessage}
    last_output::Vector{String}
    model::String
end

# Initialize AI State
function initialize_ai_state(MODEL = "claude")
    system_prompt = SYSTEM_PROMPT(get_all_project_with_URIs())
    state = AIState(
        [SystemMessage(system_prompt)],
        String[],
        MODEL,
    )
    println("\e[32mAI State initialized successfully.\e[0m")  # Green text
    return state
end

# Update system prompt
function update_system_prompt!(state::AIState)
    current_folder_structure = get_all_project_with_URIs()
    new_system_prompt = SYSTEM_PROMPT(current_folder_structure)
    state.conversation[1] = SystemMessage(new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end
