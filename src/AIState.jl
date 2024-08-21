using Dates

@kwdef mutable struct Message
    timestamp::DateTime
    role::Symbol
    content::String
    id::String=""
    itok::Int=0
    otok::Int=0
    price::Float32=0
    elapsed::Float32=0
end

mutable struct ConversationInfo
    timestamp::DateTime
    sentence::String
    id::String
    system_message::Message
    messages::Vector{Message}
end

# AI State struct
@kwdef mutable struct AIState
    conversation::Dict{String,ConversationInfo} = Dict()
    selected_conv_id::String = ""
    model::String = ""
    streaming::Bool = true
    project_path::String = ""
    skip_code_execution::Bool = false  # New flag to skip code execution
end

# Initialize AI State
function initialize_ai_state(MODEL="claude-3-5-sonnet-20240620"; resume::Bool=false, streaming::Bool=true, project_path::String="", skip_code_execution::Bool=false)
    state = AIState(model=MODEL, streaming=streaming, skip_code_execution=skip_code_execution)
    get_all_conversations_without_messages(state)
    println("\e[32mAI State initialized successfully.\e[0m ")  # Green text

    if resume
        last_conv_id = resume_last_conversation(state)
        if isempty(last_conv_id)
            generate_new_conversation(state)
            println("No previous conversation found. Starting a new conversation. Conversion id: $(state.selected_conv_id)")
        else
            println("Resumed conversation with ID: $last_conv_id")
            if !isempty(cur_conv_msgs(state))
                if cur_conv_msgs(state)[end].role == :user
                    println("Processing last unanswered message: $(cur_conv_msgs(state)[end].content)")
                    process_question(state)
                else
                    println("The last user message was answered already: \e[36m➜ \e[0m\"$(cur_conv_msgs(state)[end-1].content)\"")
                    println("So continuing from here...")
                end
            else
                println("No previous messages in this conversation.")
            end
        end
    else
        generate_new_conversation(state)
        println("Conversion id: $(state.selected_conv_id)")
    end
    update_project_path!(state, project_path)
    print_project_tree(state)
    return state
end

cur_conv_msgs(state::AIState) = state.conversation[state.selected_conv_id].messages

limit_user_messages(state::AIState) = (c = cur_conv_msgs(state); length(c) > 12 && (state.conversation[state.selected_conv_id].messages = c[end-11:end]))

system_message(state::AIState) = state.conversation[state.selected_conv_id].system_message

function set_streaming!(state::AIState, value::Bool)
    state.streaming = value
    println("\e[33mStreaming mode set to: $(value ? "enabled" : "disabled")\e[0m")
end

function get_all_conversations_without_messages(state::AIState)
    for file in get_all_conversations_file()
        id = get_id_from_file(file)
        timestamp = get_timestamp_from_file(file)
        sentence = get_conversation_from_file(file)
        state.conversation[id] = ConversationInfo(timestamp, sentence, id, Message(timestamp=now(), role=:system, content=""), Message[])
    end
end

function select_conversation(state::AIState, conversation_id)
    conversation_history = get_conversation_history(conversation_id)
    state.conversation[conversation_id].system_message = conversation_history[1]
    state.conversation[conversation_id].messages = conversation_history[2:end]
    state.selected_conv_id = conversation_id
    println("Conversation id selected: $(state.selected_conv_id)")
end

function generate_new_conversation(state::AIState)
    new_id = generate_conversation_id()
    state.selected_conv_id = new_id
    state.conversation[new_id] = ConversationInfo(
        now(),
        "",
        new_id,
        Message(timestamp=now(), role=:system, content=SYSTEM_PROMPT(state.project_path)),
        Message[]
    )
end

function update_project_path!(state::AIState, new_path::String)
    state.project_path = set_project_path(new_path)
    update_system_prompt!(state)
end

function update_system_prompt!(state::AIState; new_system_prompt="")
    new_system_prompt = new_system_prompt == "" ? SYSTEM_PROMPT(state.project_path) : new_system_prompt
    state.conversation[state.selected_conv_id].system_message = Message(timestamp=now(), role=:system, content=new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

function add_n_save_user_message!(state::AIState, user_message)
    msg = Message(timestamp=now(), role=:user, content=strip(user_message))
    push!(cur_conv_msgs(state), msg)
    save_user_message(state, msg)
end

add_n_save_ai_message!(state::AIState, ai_message) = add_n_save_ai_message!(state, Message(timestamp=now(), role=:assistant, content=strip(ai_message)))
add_n_save_ai_message!(state::AIState, ai_message, meta) = add_n_save_ai_message!(state, Message(timestamp=now(), role=:assistant, content=strip(ai_message), itok=meta.input_tokens, otok=meta.output_tokens, price=meta.price))
function add_n_save_ai_message!(state::AIState, ai_msg::Message)
    push!(cur_conv_msgs(state), ai_msg)
    save_ai_message(state, ai_msg)
end

to_dict(state::AIState) = [Dict("role" => "system", "content" => system_message(state).content); [Dict("role" => string(msg.role), "content" => msg.content) for msg in cur_conv_msgs(state)]]
to_dict_nosys(state::AIState) = [Dict("role" => string(msg.role), "content" => msg.content) for msg in cur_conv_msgs(state)]

function conversation_to_dict(state::AIState; with_sysprompt=true)
    conv = state.conversation[state.selected_conv_id]
    result = with_sysprompt ?  Dict{String,Any}[Dict(
        "timestamp" => datetime2unix(conv.system_message.timestamp),
        "role" => "system",
        "content" => conv.system_message.content,
        "id" => conv.system_message.id,
        "input_tokens" => conv.system_message.itok,
        "output_tokens" => conv.system_message.otok,
        "price" => conv.system_message.price,
        "elapsed" => conv.system_message.elapsed
    )] : Dict{String,Any}[]
    
    for message in conv.messages
        push!(result, Dict(
            "timestamp" => datetime2unix(message.timestamp),
            "role" => string(message.role),
            "content" => message.content,
            "id" => message.id,
            "input_tokens" => message.itok,
            "output_tokens" => message.otok,
            "price" => message.price,
            "elapsed" => message.elapsed
        ))
    end
    return result
end
