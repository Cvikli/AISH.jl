using AISH

# Simulate a basic run of the main function
args = ["--project-paths", ".", "--streaming"]
AISH.parse_commandline()
state = AISH.initialize_ai_state()
AISH.update_project_path_and_sysprompt!(state)
AISH.print_project_tree(state)

# Simulate processing a simple query
AISH.process_question(state, "say yes")
