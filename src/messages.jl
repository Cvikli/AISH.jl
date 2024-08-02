using Dates
using UUIDs
using PromptingTools: AbstractChatMessage, SystemMessage, UserMessage, AIMessage

const MESSAGE_SEPARATOR = "<<<AISH_MSG_59a3d6a1-8729-4e81-b876-b5aa5b6c9e2f>>>"

generate_conversation_id() = string(UUIDs.uuid4())

function save_message(conversation_id, role, message)
    timestamp = now()
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    mkpath(conversation_dir)
    
    existing_files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    if isempty(existing_files)
        first_sentence = extract_first_sentence(message)
        first_32_chars = first(replace(first_sentence, r"[^\w\s]" => ""), 32)
        filename = joinpath(conversation_dir, "$(Dates.format(timestamp, "yyyy-mm-dd_HH:MM:SS"))_$(first_32_chars)_$(conversation_id).log")
    else
        filename = joinpath(conversation_dir, sort(existing_files)[end])
    end
    
    open(filename, "a") do file
        println(file, "$(timestamp) [$(role)]: $(message)")
        println(file, MESSAGE_SEPARATOR)
    end
end

function extract_first_sentence(text)
    m = match(r"^.*?[.!?\n]", text)
    return m === nothing ? text : strip(m.match)
end

function get_conversation_history(conversation_id)
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    isempty(files) && return Message[]
    
    filename = joinpath(conversation_dir, sort(files)[end])
    content = read(filename, String)
    messages = split(content, MESSAGE_SEPARATOR, keepempty=false)
    
    return map(messages) do message
        m = match(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?) \[(\w+)\]: (.+)"s, strip(message))
        if m !== nothing
            Message(DateTime(m[1]), Symbol(m[2]), m[3])
        else
            nothing
        end
    end |> x -> filter(!isnothing, x)
end

save_system_message(conversation_id, message) = save_message(conversation_id, :system, message)
save_user_message(conversation_id, message)   = save_message(conversation_id, :user, message)
save_ai_message(conversation_id, message)     = save_message(conversation_id, :ai, message)

function get_last_user_message(conversation_id)
    history = get_conversation_history(conversation_id)
    for message in reverse(history)
        if message.role == :user
            return message.content
        end
    end
    return ""
end

function load_conversation(conversation_id)
    history = get_conversation_history(conversation_id)
    return [
        msg.role == :system ? SystemMessage(msg.content) :
        msg.role == :user ? UserMessage(msg.content) :
        msg.role == :ai ? AIMessage(msg.content) : UserMessage(msg.content)
        for msg in history
    ]
end

function get_all_conversations_file() 
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    filter(f -> occursin(r"_[\w-]+\.log$", f), readdir(conversation_dir))
end

function get_last_conversation_id()
    files = get_all_conversations_file()
    isempty(files) && return ""
    
    latest_file = sort(files)[end]
    get_id_from_file(latest_file)    
end

get_id_from_file(filename) = (m = match(r"_(?<id>[\w-]+)\.log$", filename); return m !== nothing ? m[:id] : "")

should_append_new_message(conversation) = isempty(conversation) || !(conversation[end] isa UserMessage)

function get_conversation_first_sentence(filename)
    m = match(r"\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(.+)_[\w-]+\.log$", filename)
    return m !== nothing ? m[1] : ""
end

function get_all_conversations_with_sentences()
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = get_all_conversations_file()
    return Dict(get_id_from_file(f) => get_conversation_first_sentence(f) for f in files)
end
