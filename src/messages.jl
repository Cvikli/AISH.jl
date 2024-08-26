using Dates, UUIDs

generate_conversation_id() = string(UUIDs.uuid4())


save_message(state::AIState, msg::Message) = save_message(state, msg.role, msg.content; timestamp=msg.timestamp, itok=msg.itok, otok=msg.otok, price=msg.price, elapsed=msg.elapsed)
function save_message(state::AIState, role, message; timestamp=now(UTC), itok=0, otok=0, price=0, elapsed=0)
    mkpath(CONVERSATION_DIR)
    conversation_id = state.selected_conv_id
    message_separator = get_message_separator(conversation_id)
    existing_file = get_conversation_filename(conversation_id)
    filename = isnothing(existing_file) ? generate_conversation_filename(curr_conv(state), conversation_id) : existing_file
    
    open(filename, isnothing(existing_file) ? "w" : "a") do file
        if isnothing(existing_file)
            system_msg = system_message(state)
            println(file, "$(date_format(system_msg.timestamp)) [system, in: $(system_msg.itok), out: $(system_msg.otok), price: $(system_msg.price), elapsed: $(system_msg.elapsed)]: $(system_msg.content)")
            println(file, message_separator)
        end
        println(file, "$(date_format(timestamp)) [$(role), in: $(itok), out: $(otok), price: $(price), elapsed: $(elapsed)]: $(message)")
        println(file, message_separator)
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

function get_message_by_timestamp(state::AIState, timestamp::String)
    idx = get_msg_idx_by_timestamp(state, timestamp)
    return idx !== nothing ? (idx, curr_conv_msgs(state)[idx]) : (0, nothing)
end

update_last_user_message_meta(state::AIState, meta) = update_last_user_message_meta(state, meta.input_tokens, meta.output_tokens, meta.price, meta.elapsed) 
function update_last_user_message_meta(state::AIState, itok::Int, otok::Int, price::Float32, elapsed::Float64)
    curr_conv_msgs(state)[end].itok    = itok
    curr_conv_msgs(state)[end].otok    = otok
    curr_conv_msgs(state)[end].price   = price
    curr_conv_msgs(state)[end].elapsed = elapsed
    save_conversation_to_file(curr_conv(state))
end

update_message_by_timestamp(state::AIState, timestamp::DateTime, new_content::String) = update_message_by_idx(state, get_msg_idx_by_timestamp(state, date_format(timestamp)), new_content)
update_message_by_idx(state::AIState, idx::Int, new_content::String) = ((curr_conv_msgs(state)[idx].content = new_content); save_conversation_to_file(curr_conv(state)))

function save_conversation_to_file(conv::ConversationInfo)
    filename = get_conversation_filename(conv.id)
    isnothing(filename) && (println("Error: Conversation file not found"); return)

    open(filename, "w") do file
        sys_msg = conv.system_message
        println(file, "$(date_format(sys_msg.timestamp)) [system, in: $(sys_msg.itok), out: $(sys_msg.otok), price: $(sys_msg.price), elapsed: $(sys_msg.elapsed)]: $(sys_msg.content)")
        println(file, get_message_separator(conv.id))
        for msg in conv.messages
            println(file, "$(date_format(msg.timestamp)) [$(msg.role), in: $(msg.itok), out: $(msg.otok), price: $(msg.price), elapsed: $(msg.elapsed)]: $(msg.content)")
            println(file, get_message_separator(conv.id))
        end
    end
end

function mess(message_str)
    m = match(MSG_FORMAT, strip(message_str))
    Message(
        timestamp=date_parse(m[1]),
        role=Symbol(m[2]),
        content=m[7],
        itok=parse(Int, m[3]),
        otok=parse(Int, m[4]),
        price=parse(Float32, m[5]),
        elapsed=parse(Float32, m[6])
    )
end
        
function load_conversation(conversation_id)
    filename, messages_str = read_conversation_file(conversation_id)
    isempty(filename) && return Message[]
    
    messages = [mess(msg_str) for msg_str in messages_str if !isempty(strip(msg_str))]
    messages[1], messages[2:end]
end

function resume_last_conversation(state::AIState)
    isempty(state.conversations) && return ""

    latest_conv = findmax(conv -> conv.timestamp, state.conversations)
    latest_conv_id = latest_conv[2]
    
    state.selected_conv_id = latest_conv_id
    state.conversations[latest_conv_id].system_message, state.conversations[latest_conv_id].messages = load_conversation(latest_conv_id)
    
    return latest_conv_id
end
