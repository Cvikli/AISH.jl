# using AISH

# # Simulate a typical usage scenario
# state = AISH.initialize_ai_state()
# AISH.process_question(state, "Hello, AI assistant!")
# AISH.process_message(state)
# AISH.extract_shell_commands("```sh\necho 'Hello, World!'\n```")


using PrecompileTools

@setup_workload begin
    @compile_workload begin
        # state = initialize_ai_state()
        # process_question(state, "Hello, AI assistant!")
        # process_message(state)
        # extract_shell_commands("```sh\necho 'Hello, World!'\n```")
        # start_conversation(state)
    end
end
