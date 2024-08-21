using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "project-paths"
            help = "Set one or more project paths"
            arg_type = String
            nargs = '*'  # Allow multiple arguments
            default = String[]  # Default to an empty array of strings
        "--project-paths", "-p"
            help = "Set one or more project paths (alternative way)"
            arg_type = String
            nargs = '+'  # Require at least one argument when using this option
        "--resume", "-r"
            help = "Flag to resume last conversation"
            action = :store_true
        "--streaming", "-s"
            help = "Enable streaming mode for AI responses"
            action = :store_true
        "--skip-code-execution", "-x"
            help = "Skip execution of code blocks"
            action = :store_true
    end

    return parse_args(s)
end
