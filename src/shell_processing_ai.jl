
using PromptingTools
using Random

generate_ai_command_from_meld_code(cb::CodeBlock) = generate_ai_command(cb)

function generate_ai_command(cb)
    !isfile(cb.file_path) && @warn "UNEXISTING file $(cb.file_path) pwd: $(pwd())"
    original_content = read(cb.file_path, String)
    ai_generated_content = generate_better_file(original_content, cb.pre_content)
    
    original_content, ai_generated_content
end

function improve_command_LLM(cb::CodeBlock)
    original_content, ai_generated_content = generate_ai_command_from_meld_code(cb)
    # Choose delimiter based on content
    # delimiter = if occursin("EOF", ai_generated_content)
    #     "EOF_" * randstring(3)
    # else
    #     "EOF"
    # end
    
    # Construct new meld command with AI-generated content
    # new_command = """meld $cb.file_path <(cat <<'$delimiter'
    # $ai_generated_content
    # $delimiter
    # )"""
    
    # Execute the new meld command
    return ai_generated_content
end

function generate_better_file(original_content::AbstractString, changes_content::AbstractString)
    prompt = """
    You are an AI assistant specialized in merging code changes. You will be provided with the <original content> and a <changes content> to be applied. Your task is to generate the final content after applying the <changes content>. 
    Here's what you need to do:

    1. Analyze the <original content> and the <changes content>.
    2. Apply the changes specified in the <changes content> to the <original content>.
    3. Ensure that the resulting code is syntactically correct and maintains the original structure where possible.
    4. If there are any conflicts or ambiguities, resolve them in the most logical way.
    5. Return only the final merged content, between <final content> and </final content> tags.

    <original content>
    $original_content
    </original content>

    <changes content>
    $changes_content
    </changes content>

    Please provide the final merged content between <final content> and </final content>.
    """

    println("\e[38;5;240mProcessing diff with AI for higher quality...\e[0m")
    @time aigenerated = PromptingTools.aigenerate(prompt, model="gpt4om") # gpt4om, claudeh
    return extract_final_content(aigenerated.content)
end

function extract_final_content(content::AbstractString)
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
