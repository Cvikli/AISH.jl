generate_conversation_id() = string(UUIDs.uuid4()) 

@kwdef mutable struct Message
    timestamp::DateTime
    role::Symbol
    content::String
    itok::Int=0
    otok::Int=0
    cached::Int=0
    cache_read::Int=0
    price::Float32=0
    elapsed::Float32=0
end

@kwdef mutable struct ConversationInfo
    id::String
    timestamp::DateTime=now(UTC)
    sentence::String=""
    system_message::Message=Message(timestamp=now(UTC), role=:system, content="")
    messages::Vector{Message}=[]
    rel_project_paths::Vector{String}=[]
    common_path::String=""
end

@kwdef mutable struct AIState
    conversations::Dict{String,ConversationInfo}=Dict()
    selected_conv_id::String=""
    streaming::Bool=true
    skip_code_execution::Bool=false
    model::String = ""
    contexter::AbstractContextCreator=SimpleContexter()
end

initialize_ai_state(MODEL="claude-3-5-sonnet-20240620"; contexter=SimpleContexter(), resume::Bool=false, streaming::Bool=true, project_paths::Vector{String}=String[], skip_code_execution::Bool=false, show_tokens::Bool=false) = initialize_ai_state(MODEL, resume, streaming, project_paths, skip_code_execution, show_tokens, contexter)
function initialize_ai_state(MODEL, resume, streaming, project_paths::Vector{String}, skip_code_execution, show_tokens, contexter)
    state = AIState(streaming=streaming, skip_code_execution=skip_code_execution, model=MODEL, contexter=contexter)
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

    print_project_tree(state, show_tokens=show_tokens)
    println("All things setup!")
    return state
end

set_project_path(path::String) = path !== "" && (cd(path); println("Project path initialized: $(path)"))
set_project_path(ai_state::AIState) = set_project_path(curr_conv(ai_state).common_path)
set_project_path(ai_state::AIState, paths) = begin
    curr_conv(ai_state).common_path, curr_conv(ai_state).rel_project_paths = find_common_path_and_relatives(paths)
    set_project_path(ai_state)
end

curr_proj_path(ai_state) = isempty(curr_conv(ai_state).rel_project_paths) ? "" : curr_conv(ai_state).common_path * (!isempty(curr_conv(ai_state).rel_project_paths) && curr_conv(ai_state).rel_project_paths[1] in ["", "."] ? "" : "/" * curr_conv(ai_state).rel_project_paths[1])

curr_conv(state::NamedTuple)   = (@info("Missing AIState."); state.conversations[state.selected_conv_id])
curr_conv(state::AIState)      = state.conversations[state.selected_conv_id]
curr_conv_msgs(state::AIState) = curr_conv(state).messages

limit_user_messages(state::AIState) = (c = curr_conv_msgs(state); length(c) > 12 && (state.conversations[state.selected_conv_id].messages = c[end-11:end]))

system_message(state::AIState) = state.conversations[state.selected_conv_id].system_message

function set_streaming!(state::AIState, value::Bool)
    state.streaming = value
    println("\e[33mStreaming mode set to: $(value ? "enabled" : "disabled")\e[0m")
end

function get_all_conversations_without_messages(state::AIState)
    for file in get_all_conversations_file()    
        conv_info = parse_conversation_filename(file)
        state.conversations[conv_info.id] = ConversationInfo(
            timestamp=conv_info.timestamp,
            sentence=conv_info.sentence,
            id=conv_info.id
        )
    end
end

function select_conversation(state::AIState, conversation_id)
    prev_id = state.selected_conv_id
    state.selected_conv_id = conversation_id
    curr_conv(state).system_message, curr_conv(state).messages = load_conversation(conversation_id)
    curr_conv(state).common_path, curr_conv(state).rel_project_paths = state.conversations[prev_id].common_path, state.conversations[prev_id].rel_project_paths
    println("Conversation id selected: $(state.selected_conv_id)")
end

function generate_new_conversation(state::AIState)
    prev_id = state.selected_conv_id
    new_id = generate_conversation_id()
    state.conversations[new_id] = ConversationInfo(id=new_id)
    if !isempty(prev_id)
        state.conversations[new_id].common_path      =state.conversations[prev_id].common_path
        state.conversations[new_id].rel_project_paths=state.conversations[prev_id].rel_project_paths
    end
    state.conversations[new_id].system_message = Message(timestamp=now(UTC), role=:system, content=SYSTEM_PROMPT(ctx=projects_ctx(state.conversations[new_id].rel_project_paths)))
    state.selected_conv_id = new_id
    curr_conv(state)
end

function update_project_path_and_sysprompt!(state::AIState, project_paths::Vector{String}=String[])
    !isempty(project_paths) && (set_project_path(state, project_paths))
    state.conversations[state.selected_conv_id].system_message = Message(timestamp=now(UTC), role=:system, content=SYSTEM_PROMPT(ctx=projects_ctx(curr_conv(state).rel_project_paths)))
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

add_n_save_user_message!(state::AIState, user_question::String) = add_n_save_user_message!(state, Message(timestamp=now(UTC), role=:user, content=strip(user_question)))
function add_n_save_user_message!(state::AIState, user_msg::Message)
    push!(curr_conv_msgs(state), user_msg)
    save_user_message(state, user_msg)
    user_msg
end

add_n_save_ai_message!(state::AIState, ai_message::String)       = add_n_save_ai_message!(state, Message(timestamp=now(UTC), role=:assistant, content=strip(ai_message)))
add_n_save_ai_message!(state::AIState, ai_message::String, meta::Dict) = add_n_save_ai_message!(state, Message(timestamp=now(UTC), role=:assistant, content=strip(ai_message), itok=meta["input_tokens"], otok=meta["output_tokens"], cached=meta["cache_creation_input_tokens"], cache_read=meta["cache_read_input_tokens"], price=meta["price"], elapsed=meta["elapsed"]))
function add_n_save_ai_message!(state::AIState, ai_msg::Message)
    push!(curr_conv_msgs(state), ai_msg)
    save_ai_message(state, ai_msg)
    ai_msg
end

to_dict(state::AIState) = [Dict("role" => "system", "content" => system_message(state).content); to_dict_nosys(state)]
to_dict_nosys(state::AIState) = [Dict("role" => string(msg.role), "content" => msg.content) for msg in curr_conv_msgs(state)]
to_dict_nosys_detailed(state::AIState;)= [Dict(
            "timestamp" => date_format(message.timestamp),
            "role" => string(message.role),
            "content" => message.content,
            "input_tokens" => message.itok,
            "output_tokens" => message.otok,
            "cached" => message.cached,
            "cache_read" => message.cache_read,
            "price" => message.price,
            "elapsed" => message.elapsed
        ) for message in curr_conv_msgs(state)]
