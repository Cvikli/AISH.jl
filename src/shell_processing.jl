function extract_shell_commands(content::String)
    shell_commands = Dict{String, String}()
    for m in eachmatch(r"```sh\n([\s\S]*?)\n```", content)
        code = m.captures[1]
        shell_commands[code] = ""
    end
    return shell_commands
end

function execute_shell_commands(shell_commands::Dict{String, String})
    for (code, _) in shell_commands
        output = execute_code_block(code)
        shell_commands[code] = output
    end
    return shell_commands
end
