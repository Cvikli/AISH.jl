using REPL

dialog() = print("\e[36m➜ \e[0m")  # teal arrow

function readline_improved()
    dialog()
    print("\e[1m")  # bold text
    res = readline_multi()
    print("\e[0m")  # reset text style
    return res
end

function readline_multi()
    buffer = IOBuffer()
    while true
        batch = readavailable(stdin)
        length(batch) == 1 && batch[1] == 0x0a && break
        write(buffer, batch)
    end
    return String(take!(buffer))
end