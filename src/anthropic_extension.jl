using Anthropic: ai_stream_safe
using PromptingTools: SystemMessage, UserMessage, AIMessage
using HTTP

# Anthropic.stream_response(ai_state::AIState;         model::String=ai_state.model,               max_tokens::Int=MAX_TOKEN, printout=true) = stream_response(to_dict(ai_state); model, max_tokens, printout)
# Anthropic.stream_response(messages::Vector{Message}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=MAX_TOKEN, printout=true) = stream_response(to_dict(messages); model, max_tokens, printout)

Anthropic.ai_stream_safe(ai_state::AIState; system_msg=system_message(ai_state).content, model=ai_state.model, max_tokens::Int=MAX_TOKEN, printout=true, cache=nothing) = ai_stream_safe(to_dict_nosys(ai_state); system_msg, model, max_tokens, printout, cache)
Anthropic.ai_stream_safe(conv::ConversationProcessor; model, system_msg=conv.system_message, max_tokens::Int=MAX_TOKEN, printout=true, cache=nothing) = ai_stream_safe(to_dict_nosys(conv); system_msg=system_msg.content, model, max_tokens, printout, cache)

anthropic_ask_safe(ai_state::AIState; model=ai_state.model, return_all=false, cache=nothing) = anthropic_ask_safe(curr_conv(ai_state); model, return_all, cache)
anthropic_ask_safe(conversation::ConversationInfo; model, return_all=false, cache=nothing) = begin
    conv = [
        SystemMessage(conversation.system_message.content),
        [msg.role == :user ? UserMessage(msg.content) :
         msg.role == :assistant ? AIMessage(msg.content) : UserMessage(msg.content)
         for msg in conversation.messages]...
    ]
    return ai_ask_safe(conv, model=model, return_all=return_all, max_token=min(MAX_TOKEN,4096), cache=cache)
end

