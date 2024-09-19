
using PromptingTools
using Random

function generate_ai_command_from_meld_code(command::String)
    # Extract file path and content using regex
    file_path_match = match(r"meld\s+(\S+)", command)
    content_match = match(r"<<'EOF'\n([\s\S]*?)\nEOF\n\s*\)", command)
    
    (isnothing(file_path_match) || isnothing(content_match)) && return "","Error: Invalid meld command format", ""
    file_path = file_path_match.captures[1]
    
    !isfile(file_path) && return "",command,""  # Return the original command without transformation
    patch_content = content_match.captures[1]

    original_content, ai_generated_content = generate_ai_command(file_path, patch_content)

    file_path, original_content, ai_generated_content
end

function generate_ai_command(file_path, patch_content)
    original_content = read(file_path, String)
    ai_generated_content = generate_better_file(original_content, patch_content)
    
    original_content, ai_generated_content
end

function improve_command_LLM(command::String)
    file_path, original_content, ai_generated_content = generate_ai_command_from_meld_code(command)
    # Choose delimiter based on content
    delimiter = if occursin("EOF", ai_generated_content)
        "EOF_" * randstring(3)
    else
        "EOF"
    end
    
    # Construct new meld command with AI-generated content
    new_command = """meld $file_path <(cat <<'$delimiter'
    $ai_generated_content
    $delimiter
    )"""
    
    # Execute the new meld command
    return new_command
end

function generate_better_file(original_content::String, changes_content::AbstractString)
    prompt = """
    You are an AI assistant specialized in merging code changes. Your task is to generate the final content after applying the specified changes to the original content. Follow these instructions carefully:

    1. Analyze the <original_file_content> and the <applicable_changes>.
    2. Apply the changes specified in the <applicable_changes> to the <original_file_content>.
    3. The <applicable_changes> may include comments like "// ... existing code ..." to indicate unchanged parts. Preserve these unchanged parts from the original content.
    4. Ensure that the resulting code is syntactically correct and maintains the original structure where possible.
    5. If there are any conflicts or ambiguities, resolve them in the most logical way that maintains the intended functionality.
    6. Do not remove or change any code that isn't necessary to modify to apply the <applicable_changes>.
    7. Preserve all comments, formatting, and whitespace from the original content unless explicitly changed.
    8. If the <applicable_changes> includes new code, integrate it seamlessly with the existing code.
    9. Return the complete final content, including both changed and unchanged parts, between <final content> and </final content> tags.

    <original_file_content>
    $original_content
    </original_file_content>

    <applicable_changes>
    $changes_content
    </applicable_changes>

    Provide the complete final merged content between <final content> and </final content> tags.
    """

    println("\e[38;5;240mWe AI process the diff, for higher quality diff...\e[0m")
    @time aigenerated = PromptingTools.aigenerate(prompt, model="gpt4om") # gpt4om, claudeh
    return extract_final_content(aigenerated.content)
end

function extract_final_content(content::AbstractString)
    # Find the last occurrence of <final content> and </final content>
    start_index = findfirst("<final content>", content)
    end_index = findlast("</final content>", content)
    
    if !isnothing(start_index) && !isnothing(end_index)
        # Extract the content between the last pair of tags
        start_pos = start_index.stop + 1
        end_pos = end_index.start - 1
        return content[start_pos:end_pos]
    else
        # If tags are not found, return the original content
        @warn "Tags are not found."
        return content
    end
end
