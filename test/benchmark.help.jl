
function extract_all_code(text)
	code_blocks = []
	for m in eachmatch(r"```(\w*)\n([\s\S]*?)```", text)
			language = m.captures[1]
			code = strip(m.captures[2])
			
			# Remove bash commands if present
			if language == "sh"
					code = replace(code, r".*? EOL\n"s => "")
					code = replace(code, r"\njulia.*$"s => "")
					language = "julia"
			end
			
			push!(code_blocks, (language, code))
	end
	return code_blocks
end
function format_code_blocks(text)
	code_blocks = extract_all_code(text)
	formatted_text = text
	
	# Find all code block positions
	block_positions = []
	for m in eachmatch(r"```\w*\n[\s\S]*?```", text)
			push!(block_positions, m.offset)
	end
	
	# Replace each code block with its formatted version
	for (i, (language, code)) in enumerate(reverse(code_blocks))
			start_pos = block_positions[length(block_positions) - i + 1]
			formatted_text = formatted_text[1:start_pos-1] * 
											 "```$language\n$code\n```" * 
											 formatted_text[findnext("```", formatted_text, start_pos+3)[end]+1:end]
	end
	
	return formatted_text
end



# println.(["```$lang\n$code\n```" for lang,code format_code_blocks(conversation[end].content)])
println.(format_code_blocks(textt))

