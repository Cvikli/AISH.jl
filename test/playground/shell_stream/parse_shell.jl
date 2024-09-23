
using Base.Threads

function run_command_async(cmd_str)
    cmd = `bash -c $cmd_str`
    
    # Create a pipe to capture the output
    out_pipe = Pipe()
    err_pipe = Pipe()

    # Run the command asynchronously
    process = run(pipeline(cmd, stdout=out_pipe, stderr=err_pipe), wait=false)
    close(out_pipe.in)
    close(err_pipe.in)

    # Stream output in real-time
    @async while !eof(out_pipe)
        line = readline(out_pipe)
        println(line)
    end

    # Wait for the command to finish
    wait(process)

    # Print any remaining output
    for line in eachline(out_pipe)
        println(line)
    end
end

cmd_str = "for i in {1..7}; do echo \$i; sleep 0.5; done"
run_command_async(cmd_str)

println("\nCommand execution completed.")

