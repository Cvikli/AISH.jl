using REPL

function readline_improved()
    buffer = IOBuffer()
    while true
        batch = readavailable(stdin)
        length(batch) == 1 && batch[1] == 0x0a && break
        write(buffer, batch)
    end
    return String(take!(buffer))
end