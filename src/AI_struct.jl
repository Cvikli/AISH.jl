using REPL
using InteractiveUtils
using PromptingTools
using PromptingTools: SystemMessage, UserMessage

# AI State struct
mutable struct AIState
    conversation::Vector{PromptingTools.AbstractChatMessage}
    last_output::String
    model::String
end

# Initialize AI State
function initialize_ai_state(MODEL = "claude")
    system_prompt = SYSTEM_PROMPT(get_all_project_with_URIs())
    AIState(
        [SystemMessage(system_prompt)],
        "",
        MODEL,
    )
end

# Update system prompt
function update_system_prompt!(state::AIState)
    current_folder_structure = get_all_project_with_URIs()
    new_system_prompt = SYSTEM_PROMPT(current_folder_structure)
    state.conversation[1] = SystemMessage(new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end
