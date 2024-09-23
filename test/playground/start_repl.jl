using AISH: initialize_ai_state, start_ai_repl
using EasyContext: EasyContextCreatorV4
contexter = EasyContextCreatorV4()
resume = false
project_paths=[""]

ai_state = initialize_ai_state(;contexter, resume, project_paths)
start_ai_repl(ai_state)
# julia -i -e "@async include(\"test/start_repl.jl\")"
