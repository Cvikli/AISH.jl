using Dates, UUIDs

generate_conversation_id() = string(UUIDs.uuid4())

save_message(state::AIState, msg::Message) = save_message(state, msg.role, msg.content; timestamp=msg.timestamp, itok=msg.itok, otok=msg.otok, price=msg.price, elapsed=msg.elapsed)
function save_message(state::AIState, role, message; timestamp=now(), itok=0, otok=0, price=0, elapsed=0)
    mkpath(CONVERSATION_DIR)
    conversation_id = state.selected_conv_id
    message_separator = get_message_separator(conversation_id)
    existing_file = get_conversation_filename(conversation_id)

    if isnothing(existing_file)
        conv = state.conversations[conversation_id]
        sanitized_chars = strip(replace(replace(first(conv.messages[1].content, 32), r"[^\w\s-]" => "_"), r"\s+" => "_"), '_')
        filename = joinpath(CONVERSATION_DIR, "$(Dates.format(conv.timestamp, "yyyy-mm-dd_HH:MM:SS"))_$(sanitized_chars)_$(conversation_id).log")
    else
        filename = existing_file
    end
    
    open(filename, isnothing(existing_file) ? "w" : "a") do file
        if isnothing(existing_file)
            system_msg = state.conversations[conversation_id].system_message
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

function get_conversation_history(conversation_id)
    filename, messages = read_conversation_file(conversation_id)
    isnothing(filename) && return Message[]
    
    return filter(!isnothing, map(enumerate(messages)) do (i, message)
        m = match(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?) \[(\w+), in: (\d+), out: (\d+), price: ([\d.]+), elapsed: ([\d.]+)\]: (.+)"s, strip(message))
        if m !== nothing
            Message(
                timestamp=DateTime(m[1]),
                role=Symbol(m[2]),
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
    isempty(state.conversations) && return ""

    latest_conv = findmax(conv -> conv.timestamp, state.conversations)
    latest_conv_id = latest_conv[2]
    
    state.selected_conv_id = latest_conv_id
    messages = get_conversation_history(latest_conv_id)
    state.conversations[latest_conv_id].system_message = messages[1]
    state.conversations[latest_conv_id].messages = messages[2:end]
    
    return latest_conv_id
end

update_last_user_message_meta(state::AIState, meta) = update_last_user_message_meta(state, meta.input_tokens, meta.output_tokens, meta.price, meta.elapsed) 
function update_last_user_message_meta(state::AIState, itok::Int, otok::Int, price::Float32, elapsed::Float64)
    conversation_id = state.selected_conv_id
    filename, messages = read_conversation_file(conversation_id)
    isnothing(filename) && (println("Error: Conversation file not found"); return)
    
    if !isempty(messages)
        # Remove the last empty message if it exists
        if isempty(strip(messages[end]))
            pop!(messages)
        end
        
        last_message = strip(messages[end])
        println("Last message: $last_message")
        
        m = match(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?) \[(\w+), in: (\d+), out: (\d+), price: ([\d.]+), elapsed: ([\d.]+)\]: (.+)"s, last_message)
        
        if m !== nothing
            updated_message = "$(m[1]) [$(m[2]), in: $itok, out: $otok, price: $price, elapsed: $elapsed]: $(m[7])"
            messages[end] = updated_message
            
            open(filename, "w") do file
                for (i, msg) in enumerate(messages)
                    println(file, strip(msg))
                    println(file, get_message_separator(conversation_id))
                end
            end
            
            # Update the in-memory state
            state.conversations[conversation_id].messages[end] = Message(
                timestamp=DateTime(m[1]),
                role=Symbol(m[2]),
                content=m[7],
                itok=itok,
                otok=otok,
                price=price,
                elapsed=elapsed
            )
        else
            println("Error: Failed to match the last message format")
        end
    else
        println("Error: No messages found in the conversation")
    end
end
