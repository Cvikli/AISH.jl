
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
    in_block = false
    cmd_type = :NOTHING
    block_type = ""
    file_path = ""
    last_processed_char = extractor.last_processed_index[]

    for (i, line) in enumerate(lines)
        if startswith(line, "MODIFY ")        
            file_path = String(strip(line[8:end]))
            cmd_type = :MODIFY
        elseif startswith(line, "CREATE ")
            file_path = String(strip(line[8:end]))
            cmd_type = :CREATE
        elseif startswith(line, "```") && !in_block
            in_block = true
            block_type = String(strip(line[4:end]))
        elseif in_block && length(line)>=3 && line[1:3] == "```" && (length(line)==3 || all(isspace, line[4:end]))
            command = join(current_command, '\n')
            # @show cmd_type
            # @show command
            if cmd_type == :MODIFY
                tmp = process_modify_command(String(file_path), command)
                extractor.shell_scripts[command] = @async_showerr improve_command_LLM(tmp)
            elseif cmd_type == :CREATE
                tmp = process_create_command(String(file_path), command)
                extractor.shell_scripts[command] = @async_showerr tmp
            else
                extractor.shell_scripts[command] = @async_showerr command
                # if block_type == "sh"
                #     extractor.shell_scripts[command] = @async command
                # else
                #     extractor.shell_scripts[command] = @async command
                #     @warn "is this unhandled script parsing? $(block_type)"
                # end
            end
            current_command = String[]
            in_block = false
            block_type = ""
            cmd_type = :NOTHING
            file_path = ""
            last_processed_char = length(extractor.full_content)
        elseif in_block
            push!(current_command, line)
        end
        
        # if !in_block
        #     last_processed_char += length(line) + 1  # +1 for the newline
        # end
    end

    extractor.last_processed_index[] = last_processed_char

    return extractor.shell_scripts
end
process_modify_command(file_path::String, content::String) = "meld $(file_path) <(cat <<'EOF'\n$(content)\nEOF\n)"
process_create_command(file_path::String, content::String) = "cat > $(file_path) <<'EOF'\n$(content)\nEOF"

execute_single_shell_command(code::String; no_confirm=false) = execute_code_block(startswith(code, "meld") ? improve_command_LLM(code) : code; no_confirm)

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
