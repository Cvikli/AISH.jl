
function extract_shell_commands(content::AbstractString)
    shell_scripts = OrderedDict{String, String}()
    lines = split(content, '\n')
    current_command = String[]
    in_sh_block = false
    nested_level = 0

    for line in lines
        if startswith(line, "```sh") && !in_sh_block
            in_sh_block = true
            nested_level = 1
        elseif in_sh_block
            if startswith(line, "```") && !startswith(line, "```sh")
                if occursin(r"^```\w+", line)  # Opening of a nested code block
                    nested_level += 1
                else  # Potential closing of a code block
                    nested_level -= 1
                    if nested_level == 0
                        command = join(current_command, '\n')
                        shell_scripts[command] = ""
                        current_command = String[]
                        in_sh_block = false
                        continue
                    end
                end
            end
            push!(current_command, line)
        end
    end

    # Handle case where the last shell block wasn't closed
    if in_sh_block && !isempty(current_command)
        command = join(current_command, '\n')
        shell_scripts[command] = ""
    end

    return shell_scripts
end

@kwdef mutable struct ShellScriptExtractor
    last_processed_index::Ref{Int} = Ref(0)
    shell_scripts::OrderedDict{String, Task} = OrderedDict{String, Task}()
    full_content::String = ""
end

function extract_and_preprocess_shell_scripts(new_content::String, extractor::ShellScriptExtractor)
    extractor.full_content *= new_content
    lines = split(extractor.full_content[extractor.last_processed_index[]+1:end], '\n')
    current_command = String[]
    in_sh_block = false
    last_processed_char = extractor.last_processed_index[]

    for (i, line) in enumerate(lines)
        if startswith(line, "```sh") && !in_sh_block
            in_sh_block = true
        elseif in_sh_block && startswith(line, "```")
            command = join(current_command, '\n')
            extractor.shell_scripts[command] = @async process_command(command)
            current_command = String[]
            in_sh_block = false
            last_processed_char += length(line) + 1  # +1 for the newline
        elseif in_sh_block
            push!(current_command, line)
        end
        
        if !in_sh_block
            last_processed_char += length(line) + 1  # +1 for the newline
        end
    end

    extractor.last_processed_index[] = last_processed_char

    # in_sh_block && !isempty(current_command) && @warn "Last shell block wasn't closed."

    return extractor.shell_scripts
end

execute_single_shell_command(state, code::String) = execute_code_block(state, startswith(code, "meld") ? process_meld_command(code) : code)

execute_shell_commands(state, shell_commands::Dict{String, String}) = Dict(code => execute_single_shell_command(state, code) for (code, _) in shell_commands)

function execute_shell_commands(extractor::ShellScriptExtractor; no_confirm=false)
    shell_scripts = OrderedDict{String, String}()
    
    for (command, task) in extractor.shell_scripts
        processed_command = fetch(task)
        output = execute_code_block(processed_command; original_code=command, no_confirm)
        shell_scripts[command] = output
        println("\n\e[36mCommand:\e[0m $command")
        println("\e[36mOutput:\e[0m $output")
    end
    
    return shell_scripts
end

function process_command(code::String)
    if startswith(code, "meld")
        return process_meld_command(code)
    elseif startswith(code, "cat >")
        return process_cat_command(code)
    else
        return code
    end
end

function process_cat_command(command::String)
    # Extract file path and content using regex
    match_result = match(r"cat\s+>\s+(\S+)\s+<<'EOF'\n([\s\S]*?)\nEOF", command)
    
    if isnothing(match_result)
        return "Error: Invalid cat command format"
    end
    
    file_path, content = match_result.captures
    
    # Create the directory if it doesn't exist
    mkpath(dirname(file_path))
    
    # Write the content to the file
    write(file_path, content)
    
    return "File created: $file_path"
end

