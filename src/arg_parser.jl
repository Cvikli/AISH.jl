using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "project-path"
            help = "Set the project path"
            arg_type = String
            default = ""
            required = false
        "--project-path", "-p"
            help = "Set the project path (alternative way)"
            arg_type = String
            default = ""
        "--resume", "-r"
            help = "Flag to resume last conversation"
            action = :store_true
        "--streaming", "-s"
            help = "Enable streaming mode for AI responses"
            action = :store_true
    end

    return parse_args(s)
end
