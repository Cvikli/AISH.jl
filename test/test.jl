using Base.Threads

# Start worker thread that will interrupt main after 2 seconds
@spawn begin
    sleep(2)
    println("Worker: Interrupting main...")
		ccall(:uv_kill, Cint, (Cint, Cint), getpid(), 2)  # Send SIGINT
end

# Main thread work
try
    while true
        println("Main: Working...")
        sleep(1)
    end
catch e
	@show e
    println("Main: Caught interrupt!")
end

