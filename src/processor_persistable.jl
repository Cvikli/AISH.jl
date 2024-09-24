
@kwdef mutable struct PersistableState
	conversation_path::String=""
end

Persistable(path) = (mkpath(path); PersistableState(path))

CONVERSATION_DIR(p::PersistableState) = p.conversation_path

# persist!(conv::ConversationProcessor) = save_message(conv)
# save_message(conv::ConversationProcessor) = save_conversation_to_file(conv)

to_disk_custom!(conv::ConversationProcessor, ::PersistableState) = nothing