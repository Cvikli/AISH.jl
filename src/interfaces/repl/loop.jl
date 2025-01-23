
function ai_parser(cmd, flow)
    # Process as regular input
    println("\nProcessing your request...")
    try
        run(flow, cmd)
    catch e
        if e isa InterruptException
            println("\nOperation interrupted. Normalizing conversation state...")
            flow isa STDFlow && normalize_conversation!(flow)
            return
        end
        rethrow(e)
    end
end
