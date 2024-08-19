using Dates

mutable struct Message
    timestamp::DateTime
    role::Symbol
    content::String
end

mutable struct ConversationInfo
    timestamp::DateTime
    sentence::String
    id::String
    messages::Vector{Message}
end

# AI State struct
@kwdef mutable struct AIState
    conversation::Dict{String,ConversationInfo} = Dict()
    selected_conv_id::String = ""
    model::String = ""
    streaming::Bool = true
    project_path::String = ""
end

# Initialize AI State
function initialize_ai_state(MODEL="claude-3-5-sonnet-20240620"; resume::Bool=false, streaming::Bool=true, project_path::String="")
    state = AIState(model=MODEL, streaming=streaming)
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

limit_user_messages(state::AIState) = (c = cur_conv_msgs(state); length(c) > 12 && (state.conversation[state.selected_conv_id].messages = [c[1], c[4:end]...]))

system_prompt(state::AIState) = state.conversation[state.selected_conv_id].messages[1]

function set_streaming!(state::AIState, value::Bool)
    state.streaming = value
    println("\e[33mStreaming mode set to: $(value ? "enabled" : "disabled")\e[0m")
end

function get_all_conversations_without_messages(state::AIState)
    for file in get_all_conversations_file()
        id = get_id_from_file(file)
        timestamp = get_timestamp_from_file(file)
        sentence = get_conversation_from_file(file)
        state.conversation[id] = ConversationInfo(timestamp, sentence, id, Message[])
    end
end

function select_conversation(state::AIState, conversation_id)
    state.conversation[conversation_id].messages = get_conversation_history(conversation_id)
    state.selected_conv_id = conversation_id
    println("Conversation id selected: $(state.selected_conv_id)")
end

function generate_new_conversation(state::AIState)
    new_id = generate_conversation_id()
    state.selected_conv_id = new_id
    state.conversation[new_id] = ConversationInfo(now(), "", new_id, [Message(now(), :system, SYSTEM_PROMPT(state.project_path))])
end

function update_project_path!(state::AIState, new_path::String)
    state.project_path = set_project_path(new_path)
    update_system_prompt!(state)
end

function update_system_prompt!(state::AIState; new_system_prompt="")
    new_system_prompt = new_system_prompt == "" ? SYSTEM_PROMPT(state.project_path) : new_system_prompt
    cur_conv_msgs(state)[1] = Message(now(), :system, new_system_prompt)
    println("\e[33mSystem prompt updated due to file changes.\e[0m")
end

function add_n_save_user_message!(state::AIState, user_message)
    msg = Message(now(), :user, strip(user_message))
    push!(cur_conv_msgs(state), msg)
    save_user_message(state, msg)
end

function add_n_save_ai_message!(state::AIState, ai_message)
    msg = Message(now(), :assistant, strip(ai_message))
    push!(cur_conv_msgs(state), msg)
    save_ai_message(state, msg)
end

to_dict(state::AIState) = to_dict(cur_conv_msgs(state))
to_dict(conversation::Vector{Message}) = [Dict("role" => string(msg.role), "content" => msg.content) for msg in conversation]

function conversation_to_dict(state::AIState)
    result = Dict{String,String}[]
    for message in cur_conv_msgs(state)
        push!(result, Dict(
            "timestamp" => Dates.format(message.timestamp, "yyyy-mm-dd_HH:MM:SS"),
            "role" => string(message.role),
            "message" => message.content
        ))
    end
    return result
end

function print_project_tree(path::String)
    files = get_project_files(path)
    rel_paths = sort([relpath(f, path) for f in files])
    
    println("Project structure:")
    prev_parts = String[]
    for (i, file) in enumerate(rel_paths)
        parts = splitpath(file)
        
        # Find the common prefix with the previous file
        common_prefix_length = findfirst(j -> j > length(prev_parts) || parts[j] != prev_parts[j], 1:length(parts)) - 1
        
        # Print directories that are new in this path
        for j in (common_prefix_length + 1):(length(parts) - 1)
            print_tree_line(parts[1:j], j, i == length(rel_paths), false, rel_paths[i+1:end])
        end
        
        # Print the file (or last directory)
        print_tree_line(parts, length(parts), i == length(rel_paths), true, rel_paths[i+1:end])
        
        prev_parts = parts
    end
end

function print_tree_line(parts, depth, is_last_file, is_last_part, remaining_paths)
    prefix = ""
    for k in 1:(depth - 1)
        prefix *= any(p -> startswith(p, join(parts[1:k], "/")), remaining_paths) ? "│   " : "    "
    end
    
    symbol = is_last_file && is_last_part ? "└── " : "├── "
    println(prefix * symbol * parts[end] * (is_last_part ? "" : "/"))
end
function print_project_tree(state::AIState)
    print_project_tree(state.project_path)
end
