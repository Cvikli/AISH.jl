using AISH
using PromptingTools
using DataStructures
using BoilerplateCvikli

# Simulate a basic run of the main function
args = ["--project-paths", ".", "--streaming"]
AISH.parse_commandline()
state = AISH.initialize_ai_state(no_confirm=true)
AISH.get_all_conversations_without_messages(state)
AISH.resume_last_conversation(state)
AISH.generate_new_conversation(state)
AISH.update_project_path_and_sysprompt!(state)
AISH.print_project_tree(state, show_tokens=false)

shell_results = Dict{String, String}()
# Simulate processing a simple query
AISH.process_question(state, "say yes", shell_results)
