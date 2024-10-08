using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "message"
            help = "Initial message to start the conversation"
            arg_type = String
            default = ""
        "--project-paths", "-p"
            help = "Set one or more project paths"
            arg_type = String
            nargs = '*'  # Allow multiple arguments
            default = String[]  # Default to an empty array of strings
        "--resume", "-r"
            help = "Flag to resume last conversation"
            action = :store_true
        "--skip-code-execution", "-x"
            help = "Skip execution of code blocks"
            action = :store_true
        "--tokens", "-t"
            help = "Show token count for each file"
            action = :store_true
        "--no-loop"
            help = "Disable loop mode"
            action = :store_true
        "--log-dir"
            arg_type = String
            default = joinpath(@__DIR__, "..", "conversations")
        "--no-confirm", "-y"
            help = "Run shell blocks without confirmation"
            action = :store_true
    end

    return parse_args(s)
end
