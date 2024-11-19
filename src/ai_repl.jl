using REPL
using ReplMaker
using REPL.LineEdit

function create_ai_repl(model)
    function ai_parser(user_question::String)
        cmd = strip(user_question)
        if startswith(cmd, "-p ")
            paths = split(cmd[3:end])
            update_workspace!(model, paths)
            println("\nSwitched to projects: ", join(paths, ", "))
            return
        elseif startswith(cmd, "--model ")
            new_model = strip(cmd[8:end])
            model.model = new_model
            println("\nSwitched to model: ", new_model)
            return
        elseif startswith(cmd, "-y")
            model.no_confirm = !model.no_confirm
            println("\nConfirmation ", model.no_confirm ? "disabled" : "enabled")
            return
        end
        
        if !isempty(cmd)
            println("\nProcessing your request...")
            model(user_question)
        end
        return
    end

    prompt = () -> "AISH> "

    initrepl(
        ai_parser;
        prompt_text=prompt,
        prompt_color=:cyan,
        start_key=')',
        mode_name=:ai,
    )
end

start_std_repl(;kw...) = airepl(kw...)
function airepl(;project_paths=String[], logdir=LOGDIR, show_tokens=false, silent=false, no_confirm=false, detached_git_dev=true)
    model = AIModel(;project_paths, logdir, show_tokens, silent, no_confirm, detached_git_dev)
    EasyContext.CURRENT_EDITOR = MELD_PRO

    ai_mode = create_ai_repl(model)
    println("AI REPL mode initialized. Press ')' to enter and backspace to exit.")
    println("Available commands:")
    println("  -p path1 path2    : Switch projects")
    println("  --model name      : Switch model (e.g. claude, gpt4)")
    println("  -y               : Toggle confirmation")
    ai_mode
end
