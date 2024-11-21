using AISH
using AISH: STDFlow
using PrecompileTools

@setup_workload begin
    @compile_workload begin
#         # Simulate parsing command line arguments
#         args = AISH.parse_commandline()
        
#         # Simulate starting a conversation with a simple message
#         AISH.start("Hello, AI assistant!", 
#                    resume=false, 
#                    project_paths=String[], 
#                    show_tokens=false, 
#                    logdir=AISH.LOGDIR, 
#                    loop=false, 
#                    no_confirm=true)

#         # Simulate main function call
#         AISH.main(loop=false)
        STDFlow(project_paths=String[])
    end
end
