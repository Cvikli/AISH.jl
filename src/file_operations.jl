

get_all_conversations_file() = readdir(CONVERSATION_DIR)
get_message_separator(conversation_id) = "===AISH_MSG_$(conversation_id)==="
get_conversation_filename(conversation_id) = (files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(CONVERSATION_DIR)); isempty(files) ? nothing : joinpath(CONVERSATION_DIR, first(files)))

get_id_from_file(filename) = (m = match(r"^\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(.+)_(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.log$", filename); return m !== nothing ? m[:id] : "")
get_timestamp_from_file(filename) = (m = match(r"^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2})_", filename); return m !== nothing ? DateTime(m[1], "yyyy-mm-dd_HH:MM:SS") : nothing)
get_conversation_from_file(filename) = (m = match(r"\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(.+)_[\w-]+\.log$", filename); return m !== nothing ? m[1] : "")

function read_conversation_file(conversation_id)
	filename = get_conversation_filename(conversation_id)
	isnothing(filename) && return nothing, String[]

	content = read(filename, String)
	messages = split(content, get_message_separator(conversation_id), keepempty=false)
	
	return filename, messages
end
