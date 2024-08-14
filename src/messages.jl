using Dates, UUIDs

const CONVERSATION_DIR = joinpath(@__DIR__, "..", "conversation")

get_all_conversations_file() = readdir(CONVERSATION_DIR)
generate_conversation_id() = string(UUIDs.uuid4())
get_message_separator(conversation_id) = "===AISH_MSG_$(conversation_id)==="

save_message(state::AIState, msg::Message) = save_message(state, msg.role, msg.content; timestamp=msg.timestamp)
function save_message(state::AIState, role, message; timestamp=now())
    mkpath(CONVERSATION_DIR)
    conversation_id = state.selected_conv_id
    message_separator = get_message_separator(conversation_id)
    existing_file = get_conversation_filename(conversation_id)

    if isnothing(existing_file)
        first_user_message = cur_conv_msgs(state)[2]
        sanitized_chars = strip(replace(replace(first(first_user_message.content, 32), r"[^\w\s-]" => "_"), r"\s+" => "_"), '_')
        state.conversation[conversation_id] = ConversationInfo(
            first_user_message.timestamp,
            sanitized_chars,
            conversation_id,
            cur_conv_msgs(state)
        )
        filename = joinpath(CONVERSATION_DIR, "$(Dates.format(first_user_message.timestamp, "yyyy-mm-dd_HH:MM:SS"))_$(sanitized_chars)_$(conversation_id).log")
    else
        filename = existing_file
    end
    if length(cur_conv_msgs(state)) >= 2
        open(filename, isnothing(existing_file) ? "w" : "a") do file
            if isnothing(existing_file) || length(cur_conv_msgs(state)) == 2
                for msg in cur_conv_msgs(state)
                    println(file, "$(msg.timestamp) [$(msg.role)]: $(msg.content)")
                    println(file, message_separator)
                end
            else
                println(file, "$(timestamp) [$(role)]: $(message)")
                println(file, message_separator)
            end
        end
    end
end


save_system_message(state::AIState, message::Message) = save_message(state, message)
save_user_message(state::AIState, message::Message) = save_message(state, message)
save_ai_message(state::AIState, message::Message) = save_message(state, message)
save_system_message(state::AIState, message) = save_message(state, :system, message)
save_user_message(state::AIState, message) = save_message(state, :user, message)
save_ai_message(state::AIState, message) = save_message(state, :assistant, message)

get_conversation_filename(conversation_id) = (files = filter(f -> endswith(f, "_$(conversation_id).log"), get_all_conversations_file()); return isempty(files) ? nothing : joinpath(CONVERSATION_DIR, files[1]))
get_id_from_file(filename) = (m = match(r"^\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(.+)_(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.log$", filename); return m !== nothing ? m[:id] : "")
get_timestamp_from_file(filename) = (m = match(r"^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2})_", filename); return m !== nothing ? DateTime(m[1], "yyyy-mm-dd_HH:MM:SS") : nothing)
get_conversation_from_file(filename) = (m = match(r"\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(.+)_[\w-]+\.log$", filename); return m !== nothing ? m[1] : "")

function get_conversation_history(conversation_id)
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    isempty(files) && return Message[]

    filename = joinpath(conversation_dir, files[1])
    
    content = read(filename, String)
    messages = split(content, get_message_separator(conversation_id), keepempty=false)
    
    return filter(!isnothing, map(messages) do message
        m = match(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?) \[(\w+)\]: (.+)"s, strip(message))
        if m !== nothing
            Message(DateTime(m[1]), Symbol(m[2]), m[3])
        else
            nothing
        end
    end)
end

function resume_last_conversation(state::AIState)
    isempty(state.conversation) && return ""

    latest_conv = findmax(conv -> conv.timestamp, state.conversation)
    latest_conv_id = latest_conv[2]
    
    state.selected_conv_id = latest_conv_id
    state.conversation[latest_conv_id].messages = get_conversation_history(latest_conv_id)
    
    return latest_conv_id
end