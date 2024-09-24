
@kwdef mutable struct ConversationProcessor
	id::String=genid()
	timestamp::DateTime=now(UTC)
	sentence::String=""
	system_message::Union{Message,Nothing}=nothing# =Message(id=genid(), timestamp=now(UTC), role=:system, content="")
	messages::Vector{Message}=[]
	max_history::Int = 10
end
save!(conv::ConversationProcessor, msg::Message) =  begin
	push!(conv.messages, msg)
	if length(conv.messages) > conv.max_history
			cut_history!(conv, keep=conv.max_history)
	end
	return msg
end

get_cache_setting(conv::ConversationProcessor) = begin
	if length(conv.messages) >= conv.max_history - 2
			@info "We do not cache, because next message is a cut!"
			return nothing
	end
	return :all
end

add_ai_message!(conv::ConversationProcessor, ai_message::String, meta::Dict) = add_ai_message!(conv, create_AI_message(ai_message, meta))
add_ai_message!(conv::ConversationProcessor, ai_message::String)             = add_ai_message!(conv, create_AI_message(ai_message))
add_ai_message!(conv::ConversationProcessor, ai_msg::Message)                = (push!(curr_conv_msgs(conv), ai_msg); return ai_msg)
add_error_message!(conv::ConversationProcessor, error_content::String) = begin
	return if conv.messages[end].role == :user 
		add_ai_message!(conv, error_content)
	elseif conv.messages[end].role == :assistant 
		update_message_by_id(conv, conv.messages[end].id, conv.messages[end].content * error_content)
	else
		add_user_message!(conv, error_content)
	end
end
update_message_by_idx(conv::ConversationProcessor, idx::Int, new_content::String) = ((conv.messages[idx].content = new_content); conv.messages[idx])
update_message_by_id(conv::ConversationProcessor, message_id::String, new_content::String) = begin
	idx = get_message_by_id(conv, message_id)
	isnothing(idx) && @assert false "message with the specified id: $id wasnt found! " 
	update_message_by_idx(conv, idx, new_content)
end

get_message_by_id(conv::ConversationProcessor, message_id::String) = findfirst(msg -> msg.id == message_id, conv.messages)


to_dict(conv::ConversationProcessor) = [Dict("role" => "system", "content" => conv.system_message); to_dict_nosys(conv)]
to_dict_nosys(conv::ConversationProcessor) = [Dict("role" => string(msg.role), "content" => msg.content) for msg in conv.messages]
to_dict_nosys_detailed(conv::ConversationProcessor) = [to_dict(message) for message in conv.messages]

update_last_user_message_meta(conv::ConversationProcessor, meta)           = update_last_user_message_meta(conv,                  meta["input_tokens"], meta["output_tokens"], meta["cache_creation_input_tokens"], meta["cache_read_input_tokens"], meta["price"], meta["elapsed"]) 
function update_last_user_message_meta(conv::ConversationProcessor, itok::Int, otok::Int, cached::Int, cache_read::Int, price, elapsed::Float64)
    conv.messages[end].itok       = itok
    conv.messages[end].otok       = otok
    conv.messages[end].cached     = cached
    conv.messages[end].cache_read = cache_read
    conv.messages[end].price      = price
    conv.messages[end].elapsed    = elapsed
    conv.messages[end]
end
