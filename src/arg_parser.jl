using ArgParse
using EasyContext: MELD, MELD_PRO, VIMDIFF
import EasyContext

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
            default = LOGDIR
        "--analytics-dir"
            arg_type = String
            default = ANALYTICSDIR
        "--no-confirm", "-y"
            help = "Run shell blocks without confirmation"
            action = :store_true
        "--git"
            help = "Enable detached git development workspace feature. It creates separate worktrees per session for version control and to keep the original repository intact and allow parallel workflow of 2-5-20 feature for the AIs."
            action = :store_true
        "--editor", "-e"
            help = "Select editor for code modifications (meld, vimdiff, meld_pro)"
            arg_type = String
            default = "meld"
    end

    args = parse_args(s)
    
    # Set editor based on argument
    editor_map = Dict("meld" => MELD, "vimdiff" => VIMDIFF, "meld_pro" => MELD_PRO)
    EasyContext.CURRENT_EDITOR = get(editor_map, lowercase(args["editor"]), MELD)
    
    return args
end

