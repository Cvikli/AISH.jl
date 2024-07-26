include("AI_config.jl")
include("AI_prompt.jl")
include("AI_struct.jl")
include("arg_parser.jl")

include("error_managers/anthropic_error_handler.jl")

include("input_source/speech2text.jl")
include("input_source/dummy_text.jl")
include("input_source/keyboard.jl")
include("input_source/detect_command.jl")


include("save_user_messages.jl")
include("process_query.jl")
