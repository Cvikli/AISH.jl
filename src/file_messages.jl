save_message(state::AIState, msg::Message) = save_message(state, msg.role, msg.content; id=msg.id, timestamp=msg.timestamp, itok=msg.itok, otok=msg.otok, cached=msg.cached, cache_read=msg.cache_read, price=msg.price, elapsed=msg.elapsed)
function save_message(state::AIState, role, message; id=string(UUIDs.uuid4()), timestamp=now(UTC), itok=0, otok=0, cached=0, cache_read=0, price=0, elapsed=0)
    mkpath(CONVERSATION_DIR)
    conversation_id = state.selected_conv_id
    message_separator = get_message_separator(conversation_id)
    existing_file = get_conversation_filename(conversation_id)
    filename = isnothing(existing_file) ? generate_conversation_filename(curr_conv(state), conversation_id) : existing_file
    
    open(filename, isnothing(existing_file) ? "w" : "a") do file
        if isnothing(existing_file)
            system_msg = system_message(state)
            println(file, "$(date_format(system_msg.timestamp)) [system, id: $(system_msg.id), in: $(system_msg.itok), out: $(system_msg.otok), cached: $(cached), cache_read: $(cache_read), price: $(system_msg.price), elapsed: $(system_msg.elapsed)]: $(system_msg.content)")
            println(file, message_separator)
        end
        println(file, "$(date_format(timestamp)) [$(role), id: $(id), in: $(itok), out: $(otok), cached: $(cached), cache_read: $(cache_read), price: $(price), elapsed: $(elapsed)]: $(message)")
        println(file, message_separator)
    end
end
function save_conversation_to_file(conv::ConversationInfo)  # TODO this seems to be a redundancy of file print...
    filename = get_conversation_filename(conv.id)
    isnothing(filename) && (println("Error: Conversation file not found"); return)

    open(filename, "w") do file
        sys_msg = conv.system_message
        println(file, "$(date_format(sys_msg.timestamp)) [system, id: $(sys_msg.id), in: $(sys_msg.itok), out: $(sys_msg.otok), cached: $(sys_msg.cached), cache_read: $(sys_msg.cache_read), price: $(sys_msg.price), elapsed: $(sys_msg.elapsed)]: $(sys_msg.content)")
        println(file, get_message_separator(conv.id))
        for msg in conv.messages
            println(file, "$(date_format(msg.timestamp)) [$(msg.role), id: $(msg.id), in: $(msg.itok), out: $(msg.otok), cached: $(sys_msg.cached), cache_read: $(sys_msg.cache_read), price: $(msg.price), elapsed: $(msg.elapsed)]: $(msg.content)")
            println(file, get_message_separator(conv.id))
        end
    end
end

save_system_message(state::AIState, message::Message) = save_message(state, message)
save_user_message(state::AIState, message::Message) = save_message(state, message)
save_ai_message(state::AIState, message::Message) = save_message(state, message)
save_system_message(state::AIState, message) = save_message(state, :system, message)
save_user_message(state::AIState, message) = save_message(state, :user, message)
save_ai_message(state::AIState, message) = save_message(state, :assistant, message)

get_msg_idx_by_timestamp(state, timestamp) = findfirst(msg -> begin
# @show timestamp
# @show date_format(msg.timestamp)
date_format(msg.timestamp) == timestamp
end, curr_conv_msgs(state))

update_last_user_message_meta(state::AIState, meta) = update_last_user_message_meta(state, meta["input_tokens"], meta["output_tokens"], meta["cache_creation_input_tokens"], meta["cache_read_input_tokens"], meta["price"], meta["elapsed"]) 
function update_last_user_message_meta(state::AIState, itok::Int, otok::Int, cached::Int, cache_read::Int, price, elapsed::Float64)
    curr_conv_msgs(state)[end].itok       = itok
    curr_conv_msgs(state)[end].otok       = otok
    curr_conv_msgs(state)[end].cached     = cached
    curr_conv_msgs(state)[end].cache_read = cache_read
    curr_conv_msgs(state)[end].price      = price
    curr_conv_msgs(state)[end].elapsed    = elapsed
    save_conversation_to_file(curr_conv(state))
end

update_message_by_timestamp(state::AIState, timestamp::DateTime, new_content::String) = update_message_by_idx(state, get_msg_idx_by_timestamp(state, date_format(timestamp)), new_content)
update_message_by_idx(state::AIState, idx::Int, new_content::String) = ((curr_conv_msgs(state)[idx].content = new_content); save_conversation_to_file(curr_conv(state)))


function mess(message_str)
    m = match(MSG_FORMAT, strip(message_str))
    Message(
        id=string(m[3]),  
        timestamp=date_parse(m[1]),
        role=Symbol(m[2]),
        content=m[10],
        itok=parse(Int, m[4]),
        otok=parse(Int, m[5]),
        cached=parse(Int, m[6]),
        cache_read=parse(Int, m[7]),
        price=parse(Float32, m[8]),
        elapsed=parse(Float32, m[9])
    )
end
        
function load_conversation(conversation_id)
    filename, messages_str = read_conversation_file(conversation_id)
    isempty(filename) && return false, UndefMessage(), Message[]
    
    messages = [mess(msg_str) for msg_str in messages_str if !isempty(strip(msg_str))]
    true, messages[1], messages[2:end]
end

function resume_last_conversation(state::AIState)
    isempty(state.conversations) && return ""

    latest_conv = findmax(conv -> conv.timestamp, state.conversations)
    latest_conv_id = latest_conv[2]
    
    state.selected_conv_id = latest_conv_id
    state.conversations[latest_conv_id].system_message, state.conversations[latest_conv_id].messages = load_conversation(latest_conv_id)
    
    return latest_conv_id
end

function update_message_meta(state::AIState, message_id::String, meta::Dict)
    idx, msg = get_message_by_id(state, message_id)
    if msg !== nothing
        msg.itok = meta["input_tokens"]
        msg.otok = meta["output_tokens"]
        msg.cached = meta["cache_creation_input_tokens"]
        msg.cache_read = meta["cache_read_input_tokens"]
        msg.price = meta["price"]
        msg.elapsed = meta["elapsed"]
        save_conversation_to_file(curr_conv(state))
    end
end
