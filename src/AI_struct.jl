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
initialize_ai_state(MODEL = "claude") = AIState(PromptingTools.AbstractChatMessage[SystemMessage(SYSTEM_PROMPT)], "", MODEL)
