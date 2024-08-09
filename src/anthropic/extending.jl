using Anthropic: stream_response

Anthropic.stream_response(ai_state::AIState; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=1024) = Anthropic.stream_response(to_dict(ai_state); model, max_tokens)
Anthropic.stream_response(messages::Vector{Message}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=1024) = Anthropic.stream_response(to_dict(messages); model, max_tokens)
