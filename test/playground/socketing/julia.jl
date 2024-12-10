using WebSockets

WebSockets.open("ws://localhost:8080") do ws
    # Send a test message
    write(ws, "Hello from Julia!")
    
    # Listen for messages until the socket closes
    while !eof(ws)
        msg = read(ws, String)
        println("Received from server: $msg")
    end
end
