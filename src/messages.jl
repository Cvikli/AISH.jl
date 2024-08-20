using Dates, UUIDs

get_all_conversations_file() = readdir(CONVERSATION_DIR)
generate_conversation_id() = string(UUIDs.uuid4())
get_message_separator(conversation_id) = "===AISH_MSG_$(conversation_id)==="

save_message(state::AIState, msg::Message) = save_message(state, msg.role, msg.content; timestamp=msg.timestamp, itok=msg.itok, otok=msg.otok, price=msg.price, elapsed=msg.elapsed)
function save_message(state::AIState, role, message; timestamp=now(), itok=0, otok=0, price=0, elapsed=0)
    mkpath(CONVERSATION_DIR)
    conversation_id = state.selected_conv_id
    message_separator = get_message_separator(conversation_id)
    existing_file = get_conversation_filename(conversation_id)

    if isnothing(existing_file)
        conv = state.conversation[conversation_id]
        sanitized_chars = strip(replace(replace(first(conv.messages[1].content, 32), r"[^\w\s-]" => "_"), r"\s+" => "_"), '_')
        filename = joinpath(CONVERSATION_DIR, "$(Dates.format(conv.timestamp, "yyyy-mm-dd_HH:MM:SS"))_$(sanitized_chars)_$(conversation_id).log")
    else
        filename = existing_file
    end
    
    open(filename, isnothing(existing_file) ? "w" : "a") do file
        if isnothing(existing_file)
            system_msg = state.conversation[conversation_id].system_message
            println(file, "$(system_msg.timestamp) [system, in: $(system_msg.itok), out: $(system_msg.otok), price: $(system_msg.price), elapsed: $(system_msg.elapsed)]: $(system_msg.content)")
            println(file, message_separator)
        end
        println(file, "$(timestamp) [$(role), in: $(itok), out: $(otok), price: $(price), elapsed: $(elapsed)]: $(message)")
        println(file, message_separator)
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
    filename = get_conversation_filename(conversation_id)
    isnothing(filename) && return Message[]
    
    content = read(filename, String)
    messages = split(content, get_message_separator(conversation_id), keepempty=false)
    
    return filter(!isnothing, map(enumerate(messages)) do (i, message)
        m = match(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?) \[(\w+), in: (\d+), out: (\d+), price: ([\d.]+), elapsed: ([\d.]+)\]: (.+)"s, strip(message))
        if m !== nothing
            Message(
                timestamp=DateTime(m[1]),
                role=i == 1 ? :system : Symbol(m[2]),
                content=m[7],
                itok=parse(Int, m[3]),
                otok=parse(Int, m[4]),
                price=parse(Float32, m[5]),
                elapsed=parse(Float32, m[6])
            )
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
    messages = get_conversation_history(latest_conv_id)
    state.conversation[latest_conv_id].system_message = messages[1]
    state.conversation[latest_conv_id].messages = messages[2:end]
    
    return latest_conv_id
end
