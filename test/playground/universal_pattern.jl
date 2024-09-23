

@kwdef mutable struct Message
	id::String
	timestamp::DateTime
	role::Symbol
	content::String
end
Message(timestamp::DateTime, role::String, content::String) = Message(bytes2hex(sha256("$timestamp" * content)), timestamp, role, content)

@kwdef mutable struct Query
	id::String=genid()
	timestamp::DateTime
	data::Vector{Union{Message,CodeBlock,ShellResults}}
	itok::Int=0
	otok::Int=0
	cached::Int=0
	cache_read::Int=0
	price::Float32=0
	elapsed::Float32=0
end


