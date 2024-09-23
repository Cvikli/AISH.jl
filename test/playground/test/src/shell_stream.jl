
using Base
using Base.Threads

stream_shell_command(comm) = stream_shell_command(`sh -c $comm`)
function stream_shell_command(cmd::Cmd)

  out = Pipe()
  err = Pipe()

  process = run(pipeline(ignorestatus(cmd), stdout=out, stderr=err))
  close(out.in)
  close(err.in)

  (
    stdout = String(read(out)), 
    stderr = String(read(err)),  
    code = process.exitcode
  )
end

# Hardcoded example
const EXAMPLE_COMMAND = "for i in {1..10}; do echo \$i; sleep 1; done"

# Run the example
println("Running command: $EXAMPLE_COMMAND")
stream_shell_command(EXAMPLE_COMMAND)
println("Script execution completed.")


