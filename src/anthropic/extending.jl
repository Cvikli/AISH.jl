using Anthropic: stream_response, ai_stream_safe
using PromptingTools: SystemMessage, UserMessage, AIMessage
using HTTP

Anthropic.stream_response(ai_state::AIState;         model::String=ai_state.model,               max_tokens::Int=1024, printout=true) = stream_response(to_dict(ai_state); model, max_tokens, printout)
Anthropic.stream_response(messages::Vector{Message}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=1024, printout=true) = stream_response(to_dict(messages); model, max_tokens, printout)

Anthropic.ai_stream_safe(ai_state::AIState; model=ai_state.model, max_tokens::Int=1024, printout=true) = Anthropic.ai_stream_safe(to_dict(ai_state); model, max_tokens, printout)

anthropic_ask_safe(ai_state::AIState; model=ai_state.model, return_all=false) = anthropic_ask_safe(cur_conv_msgs(state); model, return_all)
anthropic_ask_safe(conversation::Vector{Message}; model, return_all=false) = begin
	conv = [
			msg.role == :system ? SystemMessage(msg.content) :
			msg.role == :user ? UserMessage(msg.content) :
			msg.role == :assistant ? AIMessage(msg.content) : UserMessage(msg.content)
			for msg in conversation
	]
	return ai_ask_safe(conv, model=model, return_all=return_all)
end
