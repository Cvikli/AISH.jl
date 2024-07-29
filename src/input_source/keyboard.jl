using REPL

function readline_improved()
    println("Enter your multiline input (press Enter on an empty line to finish):")
    buffer = IOBuffer()
    print("➜ ")
    while true
        batch = readavailable(stdin)
        length(batch) == 1 && batch[1] == 0x0a && break
        write(buffer, batch)
    end
    return String(take!(buffer))
end