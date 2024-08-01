using Dates
using UUIDs
using PromptingTools: AbstractChatMessage

const MESSAGE_SEPARATOR = "<<<AISH_MSG_59a3d6a1-8729-4e81-b876-b5aa5b6c9e2f>>>"

generate_conversation_id() = return string(UUIDs.uuid4())

function save_message(conversation_id, role, message)
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH:MM:SS")
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    mkpath(conversation_dir)
    
    # Find existing file or create a new one
    existing_files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    if isempty(existing_files)
        filename = joinpath(conversation_dir, "$(timestamp)_$(conversation_id).log")
    else
        filename = joinpath(conversation_dir, sort(existing_files)[end])
    end
    
    open(filename, "a") do file
        println(file, "$timestamp [$role]: $message")
        println(file, MESSAGE_SEPARATOR)
    end
end

function get_conversation_history(conversation_id)
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    isempty(files) && return []
    
    filename = joinpath(conversation_dir, sort(files)[end])  # Get the most recent file
    content = read(filename, String)
    messages = split(content, MESSAGE_SEPARATOR, keepempty=false)
    history = []
    for message in messages
        m = match(r"(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}) \[(user|ai|system)\]: (.+)"s, strip(message))
        if m !== nothing
            push!(history, Dict("timestamp" => m[1], "role" => m[2], "message" => m[3]))
        end
    end
    return history
end

save_system_message(conversation_id, message) = save_message(conversation_id, "system", message)
save_user_message(conversation_id, message)   = save_message(conversation_id, "user", message)
save_ai_message(conversation_id, message)     = save_message(conversation_id, "ai", message)

function get_last_user_message(conversation_id)
    history = get_conversation_history(conversation_id)
    for entry in reverse(history)
        if entry["role"] == "user"
            return entry["message"]
        end
    end
    return ""
end

function load_conversation(conversation_id)
    history = get_conversation_history(conversation_id)
    return AbstractChatMessage[
        msg["role"] == "system" ? SystemMessage(msg["message"]) :
        msg["role"] == "user" ? UserMessage(msg["message"]) :
        msg["role"] == "ai" ? AIMessage(msg["message"]) : UserMessage(msg["message"])
        for msg in history
    ]
end
function get_all_conversations_file() 
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = filter(f -> occursin(r"_[\w-]+\.log$", f), readdir(conversation_dir))
end
function get_last_conversation_id()
    files = get_all_conversations_file()
    isempty(files) && return ""
    
    latest_file = sort(files)[end]
    get_id_from_file(latest_file)    
end
get_id_from_file(filename) = (m = match(r"_(?<id>[\w-]+)\.log$", filename); return m !== nothing ? m[:id] : "")

should_append_new_message(conversation) = isempty(conversation) || !(conversation[end] isa UserMessage)
