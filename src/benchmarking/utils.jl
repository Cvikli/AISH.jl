
function extract_sh_block_to_julia_code(input_string)
	@show "input_string"
	println(input_string)
	# Regular expression to match the code block
	code_block_regex = r"```sh\n(.*?)```\n"s
	
	# Find the code block
	m = match(code_block_regex, input_string)
	# display(m)
	m === nothing && return input_string
	
	# Extract the code content
	code_content = m.captures[1]
	# @show "code_contentdefefe"
	# println(code_content)
	
	# Remove the bash command (everything up to and including the first EOL)
	julia_code = replace(code_content, r".*?\"EOL\"\n"s => "")
	# @show "julia_codeeeee"
	# println(julia_code)
	
	# Remove the last line (julia event_scheduler.jl)
	julia_code = replace(julia_code, r"\nEOL.*"s => "")
	# @show "julia_cod-.----------------"
	# println(julia_code)
	
	# Construct the modified string
	modified_string = replace(input_string, code_block_regex => "```julia\n$julia_code\n```")
	return modified_string
end

print_score(res) = println("Parsed: $(res.parsed) Executed: $(res.executed), P: $(res.unit_tests_passed)/$(res.unit_tests_count), E: $(res.examples_executed)/$(res.examples_count), $(res.elapsed_seconds)s, \$$(res.cost) Label: $(res.prompt_label) ") 


# #%%

# asdf = "read -q \"?continue? (y) \" && cat > src/event_scheduler.jl <<-\"EOL\"\nusing Dates\n\nfunction event_scheduler(events::Vector{Tuple{String, String}})\n    isempty(events) && return \"No events\"\n    \n    parsed_events = [(DateTime(start, \"yyyy-mm-dd HH:MM\"), DateTime(finish, \"yyyy-mm-dd HH:MM\")) for (start, finish) in events]\n    sorted_events = sort(parsed_events)\n    \n    for i in 1:length(sorted_events)-1\n        if sorted_events[i][2] > sorted_events[i+1][1]\n            return \"Conflict\"\n        end\n    end\n    \n    return \"No conflicts\"\nend\nEOL\n"
# replace(asdf, r".*?\"EOL\"\n"s => "")