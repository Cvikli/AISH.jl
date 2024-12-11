using WebSockets
using JSON3

WebSockets.open("ws://localhost:8080") do ws
    # Subscribe to a channel
    write(ws, JSON3.write((
        type = "subscribe",
        channel = "julia-channel"
    )))

    # Send a test message
    write(ws, JSON3.write((
        type = "message",
        channel = "julia-channel",
        content = "Hello from Julia!"
    )))

    while !eof(ws)
        msg = read(ws, String)
        data = JSON3.read(msg)
        println("Received on channel $(data.channel): $(data.content)")
    end
end
