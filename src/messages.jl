using Dates
using UUIDs
using PromptingTools: AbstractChatMessage, SystemMessage, UserMessage, AIMessage

const MESSAGE_SEPARATOR = "<<<AISH_MSG_59a3d6a1-8729-4e81-b876-b5aa5b6c9e2f>>>"

generate_conversation_id() = string(UUIDs.uuid4())

function save_message(state::AIState, role, message)
    
    if length(cur_conv(state)) >= 2
        conversation_id = state.selected_conv_id
        conversation_dir = joinpath(@__DIR__, "..", "conversation")
        mkpath(conversation_dir)
        first_sentence = cur_conv(state)[2]
        first_32_chars = first(first_sentence.content, 32)
        sanitized_chars = replace(first_32_chars, r"[^\w\s-]" => "_")
        sanitized_chars = replace(sanitized_chars, r"\s+" => "_")
        sanitized_chars = strip(sanitized_chars, '_')
        
        filename = joinpath(conversation_dir, "$(Dates.format(first_sentence.timestamp, "yyyy-mm-dd_HH:MM:SS"))_$(sanitized_chars)_$(conversation_id).log")
        
        if length(cur_conv(state)) == 2
            state.conversation_sentences[conversation_id] = sanitized_chars
            system_message = system_prompt(state)
            open(filename, "w") do file
                println(file, "$(system_message.timestamp) [$(system_message.role)]: $(system_message.content)")
                println(file, MESSAGE_SEPARATOR)
                println(file, "$(first_sentence.timestamp) [$(first_sentence.role)]: $(first_sentence.content)")
                println(file, MESSAGE_SEPARATOR)
            end
        else
            timestamp = now()
            open(filename, "a") do file
                println(file, "$(timestamp) [$(role)]: $(message)")
                println(file, MESSAGE_SEPARATOR)
            end
        end
        
    end
    
end


function get_conversation_history(conversation_id)
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    files = filter(f -> endswith(f, "_$(conversation_id).log"), readdir(conversation_dir))
    isempty(files) && return Message[]
    
    filename = joinpath(conversation_dir, sort(files)[end])
    !isfile(filename) && return Message[]
    
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

save_system_message(state::AIState, message) = save_message(state, :system, message)
save_user_message(state::AIState, message)   = save_message(state, :user, message)
save_ai_message(state::AIState, message)     = save_message(state, :ai, message)

function get_last_user_message(conversation_id)
    history = get_conversation_history(conversation_id)
    for message in reverse(history)
        if message.role == :user
            return message.content
        end
    end
    return ""
end


get_all_conversations_file()  = joinpath(@__DIR__, "..", "conversation")

function get_last_conversation_id()
    files = get_all_conversations_file()
    isempty(files) && return ""
    
    latest_file = sort(files)[end]
    get_id_from_file(latest_file)    
end

should_append_new_message(conversation) = isempty(conversation) || !(conversation[end] isa UserMessage)

get_id_from_file(filename) = (m = match(r"_(?<id>[\w-]+)\.log$", filename); return m !== nothing ? m[:id] : "")

function get_conversation_first_sentence(filename)
    m = match(r"\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}_(.+)_[\w-]+\.log$", filename)
    return m !== nothing ? m[1] : ""
end

function get_all_conversations_with_sentences()
    conversation_dir = joinpath(@__DIR__, "..", "conversation")
    return Dict(get_id_from_file(f) => get_conversation_first_sentence(f) for f in readdir(conversation_dir))
end
