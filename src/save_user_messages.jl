using Dates

function save_user_message(message)
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    filename = joinpath(@__DIR__, "..", "conversation", "user_messages.log")
    mkpath(dirname(filename))
    open(filename, "a") do file
        println(file, "$timestamp: $message")
    end
end

function get_last_user_message()
    filename = joinpath(@__DIR__, "..", "conversation", "user_messages.log")
    isfile(filename) || return ""
    lines = readlines(filename)
    isempty(lines) && return ""
    last_line = lines[end]
    return split(last_line, ": ", limit=2)[2]
end


