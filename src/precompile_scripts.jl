# using AISH

# # Simulate a typical usage scenario
# state = AISH.initialize_ai_state()
# AISH.process_question(state, "Hello, AI assistant!")
# AISH.process_message(state)
# AISH.extract_shell_commands("```sh\necho 'Hello, World!'\n```")


# using PrecompileTools

# @setup_workload begin
#     @compile_workload begin
#         # state = initialize_ai_state(no_confirm=false)
#         parse_commandline()
#         stop_spinner=progressing_spinner()
#         stop_spinner[]=true
#         # process_question(state, "Say yes!")
#         # process_message(state)
#         # extract_shell_commands("```sh\necho 'Hello, World!'\n```")
#         main(loop=false)
#     end
# end
using AISH
using PrecompileTools

@setup_workload begin
    @compile_workload begin
        # Simulate parsing command line arguments
        args = AISH.parse_commandline()
        
        # Simulate starting a conversation with a simple message
        AISH.start("Hello, AI assistant!", 
                   resume=false, 
                   project_paths=String[], 
                   show_tokens=false, 
                   logdir=AISH.LOGDIR, 
                   loop=false, 
                   no_confirm=true)

        # Simulate main function call
        AISH.main(loop=false)
    end
end
