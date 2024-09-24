


@kwdef mutable struct Message
	id::String=genid()
	timestamp::DateTime
	role::Symbol
	content::String
	itok::Int=0
	otok::Int=0
	cached::Int=0
	cache_read::Int=0
	price::Float32=0
	elapsed::Float32=0
end

UndefMessage() = Message(id="",timestamp=now(UTC), role=:UNKNOWN, content="")
create_AI_message(ai_message::String, meta::Dict) = Message(id=genid(), timestamp=now(UTC), role=:assistant, content=ai_message, itok=meta["input_tokens"], otok=meta["output_tokens"], cached=meta["cache_creation_input_tokens"], cache_read=meta["cache_read_input_tokens"], price=meta["price"], elapsed=meta["elapsed"])
create_AI_message(ai_message::String)             = Message(id=genid(), timestamp=now(UTC), role=:assistant, content=ai_message)
create_user_message(user_query) = Message(id=genid(), timestamp=now(UTC), role=:user, content=user_query)

