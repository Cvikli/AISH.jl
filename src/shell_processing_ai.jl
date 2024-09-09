using PromptingTools

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

function aigenerate(original_content::String, changes_content::String)
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

  @time aigenerated = PromptingTools.aigenerate(prompt, model="gpt4om")
  return extract_final_content(aigenerated.content)
end

function extract_final_content(content::AbstractString)
  m = match(r"<final content>(.*?)</final content>"s, content)
  return isnothing(m) ? content : strip(m.captures[1])
end

