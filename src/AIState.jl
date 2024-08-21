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

@kwdef mutable struct ConversationInfo
    timestamp::DateTime=now()
    sentence::String=""
    id::String
    system_message::Message=Message(timestamp=now(), role=:system, content="")
    messages::Vector{Message}=[]
    rel_project_paths::Vector{String}=[]
    common_path::String=""
end

# AI State struct
@kwdef mutable struct AIState
    conversations::Dict{String,ConversationInfo}=Dict()
    selected_conv_id::String=""
    streaming::Bool=true
    skip_code_execution::Bool=false
    model::String = ""
end

# Initialize AI State
function initialize_ai_state(MODEL="claude-3-5-sonnet-20240620"; resume::Bool=false, streaming::Bool=true, project_paths::Vector{String}=String[], skip_code_execution::Bool=false)
    state = AIState(streaming=streaming, skip_code_execution=skip_code_execution, model=MODEL)
    get_all_conversations_without_messages(state)
    println("\e[32mAI State initialized successfully.\e[0m ")
    
    if resume
        last_conv_id = resume_last_conversation(state)
        if isempty(last_conv_id)
            generate_new_conversation(state)
            println("No previous conversation found. Starting a new conversation. Conversion id: $(state.selected_conv_id)")
        else
            println("Resumed conversation with ID: $last_conv_id")
            if !isempty(curr_conv_msgs(state))
                if curr_conv_msgs(state)[end].role == :user
                    println("Processing last unanswered message: $(curr_conv_msgs(state)[end].content)")
                    process_message(state)
                else
                    println("The last user message was answered already: \e[36m➜ \e[0m\"$(curr_conv_msgs(state)[end-1].content)\"")
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
    update_project_path_and_sysprompt!(state, project_paths)

    print_project_tree(state)
    return state
end
set_project_path(path::String) = path !== "" && (cd(path); println("Project path initialized: $(path)"))
set_project_path(ai_state::AIState) = set_project_path(curr_conv(ai_state).common_path)
set_project_path(ai_state::AIState, paths) = begin
    curr_conv(ai_state).common_path, curr_conv(ai_state).rel_project_paths = find_common_path_and_relatives(paths)
    set_project_path(ai_state)
end

curr_conv(state::AIState) = state.conversations[state.selected_conv_id]
curr_conv_msgs(state::AIState) = curr_conv(state).messages

limit_user_messages(state::AIState) = (c = curr_conv_msgs(state); length(c) > 12 && (state.conversations[state.selected_conv_id].messages = c[end-11:end]))

system_message(state::AIState) = state.conversations[state.selected_conv_id].system_message

function set_streaming!(state::AIState, value::Bool)
    state.streaming = value
    println("\e[33mStreaming mode set to: $(value ? "enabled" : "disabled")\e[0m")
end

function get_all_conversations_without_messages(state::AIState)
    for file in get_all_conversations_file()
        id = get_id_from_file(file)
        timestamp = get_timestamp_from_file(file)
        sentence = get_conversation_from_file(file)
        state.conversations[id] = ConversationInfo(;timestamp, sentence, id)
    end
end

function select_conversation(state::AIState, conversation_id)
    conversation_history = get_conversation_history(conversation_id)
    state.conversations[conversation_id].system_message = conversation_history[1]
    state.conversations[conversation_id].messages = conversation_history[2:end]
    state.selected_conv_id = conversation_id
    println("Conversation id selected: $(state.selected_conv_id)")
end

function generate_new_conversation(state::AIState)
    new_id = generate_conversation_id()
    state.selected_conv_id = new_id
    state.conversations[new_id] = ConversationInfo(id=new_id)
end

function update_project_path_and_sysprompt!(state::AIState, project_paths::Vector{String}=String[])
    !isempty(project_paths) && (set_project_path(state, project_paths))
    state.conversations[state.selected_conv_id].system_message = Message(timestamp=now(), role=:system, content=SYSTEM_PROMPT(ctx=projects_ctx(curr_conv(state).rel_project_paths)))
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

add_n_save_user_message!(state::AIState, user_question::String) = add_n_save_user_message!(state, Message(timestamp=now(), role=:user, content=strip(user_question)))
function add_n_save_user_message!(state::AIState, user_msg::Message)
    push!(curr_conv_msgs(state), user_msg)
    save_user_message(state, user_msg)
end

add_n_save_ai_message!(state::AIState, ai_message::String)       = add_n_save_ai_message!(state, Message(timestamp=now(), role=:assistant, content=strip(ai_message)))
add_n_save_ai_message!(state::AIState, ai_message::String, meta) = add_n_save_ai_message!(state, Message(timestamp=now(), role=:assistant, content=strip(ai_message), itok=meta.input_tokens, otok=meta.output_tokens, price=meta.price, elapsed=meta.elapsed))
function add_n_save_ai_message!(state::AIState, ai_msg::Message)
    push!(curr_conv_msgs(state), ai_msg)
    save_ai_message(state, ai_msg)
end

to_dict(state::AIState) = [Dict("role" => "system", "content" => system_message(state).content); to_dict_nosys(state)]
to_dict_nosys(state::AIState) = [Dict("role" => string(msg.role), "content" => msg.content) for msg in curr_conv_msgs(state)]
to_dict_nosys_detailed(state::AIState;)= [Dict(
            "timestamp" => datetime2unix(message.timestamp),
            "role" => string(message.role),
            "content" => message.content,
            "id" => message.id,
            "input_tokens" => message.itok,
            "output_tokens" => message.otok,
            "price" => message.price,
            "elapsed" => message.elapsed
        ) for message in curr_conv_msgs(state)]
