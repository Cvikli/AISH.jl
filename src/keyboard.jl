using REPL

dialog() = print("\e[36m➜ \e[0m")  # teal arrow

function readline_multi()
    buffer = IOBuffer()
    while true
        batch = readavailable(stdin)
        length(batch) == 1 && batch[1] == 0x0a && break
        write(buffer, batch)
    end
    return String(take!(buffer))
end

function readline_improved()
    dialog()
    print("\e[1m")  # bold text
    res = readline_multi()
    clearline()
    print("\e[0m")  # reset text style
    return res
end

wait_user_question(user_question) = begin
    while is_really_empty(user_question)
        user_question = readline_improved()
    end
    user_question
end