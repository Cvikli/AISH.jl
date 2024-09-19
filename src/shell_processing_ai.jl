
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
    You are an AI code merger. Combine the original content with the specified changes:

    - Analyze the <original_file_content> and the <specified_changes>.
    - Apply the changes specified in the <specified_changes> to the <original_file_content>.
    - The <specified_changes> may include comments like "// ... existing code ..." to indicate original existing code should be inserted there. Preserve these unchanged parts from the original content.
    - Do not remove or change any code that isn't necessary to modify to apply the <specified_changes>. So if that code has relevance for the structure in the final content then keep it! 
    - Preserve all comments, formatting, and whitespace from the original content unless explicitly changed.
    - Ensure that the resulting code is syntactically correct and maintains the original structure where possible.
    - If there are any conflicts or ambiguities, resolve them in the logical way that maintains the intended functionality.
    - Return the complete final content, that is reconstructed from the original file and the changes, between <final_content> and </final_content> tags.

    <original_file_content>
    $original_content
    </original_file_content>

    <specified_changes>
    $changes_content
    </specified_changes>

    Provide the complete final merged content between <final_content> and </final_content> tags.
    """

    println("\e[38;5;240mProcessing diff with AI for higher quality...\e[0m")
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
