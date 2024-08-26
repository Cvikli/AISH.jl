



date_format(date) = Dates.format(date, DATE_FORMAT)
date_parse(date)  = DateTime(date, DATE_FORMAT)

get_all_conversations_file() = readdir(CONVERSATION_DIR)
get_message_separator(conversation_id) = "===AISH_MSG_$(conversation_id)==="
get_conversation_filename(conversation_id) = (files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(CONVERSATION_DIR)); isempty(files) ? nothing : joinpath(CONVERSATION_DIR, first(files)))

function parse_conversation_filename(filename)
    m = match(CONVERSATION_FILE_REGEX, filename)
    return isnothing(m) ? (timestamp=nothing, sentence="", id="") : (
        timestamp=date_parse(m[1]),
        sentence=m[2],
        id=m[:id]
    )
end

function generate_conversation_filename(conv::ConversationInfo, conversation_id::String)
    sanitized_chars = strip(replace(replace(first(conv.messages[1].content, 32), r"[^\w\s-]" => "_"), r"\s+" => "_"), '_')
    return joinpath(CONVERSATION_DIR, "$(date_format(conv.timestamp))_$(sanitized_chars)_$(conversation_id).log")
end

function read_conversation_file(conversation_id)
    filename = get_conversation_filename(conversation_id)
    isnothing(filename) && return "", String[]

    content = read(filename, String)
    messages = split(content, get_message_separator(conversation_id), keepempty=false)

    return filename, messages
end
