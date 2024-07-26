using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--project-path", "-p"
            help = "Set the project path"
            arg_type = String
            default = "."
    end

    return parse_args(s)
end
