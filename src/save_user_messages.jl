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
    pattern = r"(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}): (.+?)(?=\s+\d{4}-\d{2}-\d{2}|$)"
    matches = collect(eachmatch(pattern, join(lines,"\n")))
    # [(DateTime(m[1], "yyyy-mm-dd_HH-MM-SS"), m[2]) for m in matches]
    return last(matches)[2]
end


