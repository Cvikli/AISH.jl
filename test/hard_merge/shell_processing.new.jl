meld ./src/shell_processing.jl <(cat <<'EOF'
using PromptingTools

function extract_shell_commands(content::String)
    shell_commands = Dict{String, String}()
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
                        shell_commands[command] = ""
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
        shell_commands[command] = ""
    end

    return shell_commands
end

function execute_shell_commands(shell_commands::Dict{String, String})
    for (code, _) in shell_commands
        if startswith(code, "meld")
            output = process_meld_command(code)
        else
            output = execute_code_block(code)
        end
        shell_commands[code] = output
    end
    return shell_commands
end

function process_meld_command(command::String)
    parts = split(command, " ")
    file_path = parts[2]
    content_start = findfirst(x -> startswith(x, "<<'EOF'"), parts)
    if isnothing(content_start)
        return "Error: Invalid meld command format"
    end
    
    original_content = read(file_path, String)
    patch_content = join(parts[content_start+1:end-1], " ")
    
    # Generate new content using AI
    ai_generated_content = aigenerate(original_content, patch_content)
    
    # Construct new meld command with AI-generated content
    new_command = """meld $file_path <(cat <<'EOF'
$ai_generated_content
EOF
)"""
    
    # Execute the new meld command
    return execute_code_block(new_command)
end

function aigenerate(original_content::String, patch_content::String)
    prompt = """
    You are an AI assistant specialized in merging code changes. You will be provided with the original file content and a patch to be applied. Your task is to generate the final content after applying the patch. Here's what you need to do:

    1. Analyze the original content and the patch.
    2. Apply the changes specified in the patch to the original content.
    3. Ensure that the resulting code is syntactically correct and maintains the original structure where possible.
    4. If there are any conflicts or ambiguities, resolve them in the most logical way.
    5. Return only the final merged content, without any explanations or comments.

    Original content:
    ```
    $original_content
    ```

    Patch content:
    ```
    $patch_content
    ```

    Please provide the final merged content:
    """

    aigenerated = PromptingTools.aigenerate(prompt)
    return aigenerated.content
end

// ... existing code ...
EOF
)