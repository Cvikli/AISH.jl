using Base: @kwdef

@kwdef struct FileDiff
    filename::String
    old_content::String
    new_content::String
end
function extract_filename_and_content(code_block)
	lines = split(code_block, '\n')
	filename_line = findfirst(line -> startswith(line, "cat > "), lines)
	isnothing(filename_line) && return nothing, nothing
	filename = split(lines[filename_line], ' ')[3]
	content_start = findnext(line -> line == "EOL", lines, filename_line + 1)
	isnothing(content_start) && return nothing, nothing
	content = join(lines[filename_line+1:content_start-1], '\n')
	return filename, strip(content)
end

function get_current_file_content(filename)
	isfile(filename) ? read(filename, String) : ""
end

function generate_file_diff(code_block)
	filename, new_content = extract_filename_and_content(code_block)
	isnothing(filename) || isnothing(new_content) && return nothing
	old_content = get_current_file_content(String(filename))
	FileDiff(filename=filename, old_content=old_content, new_content=new_content)
end


function create_git_diff_view(old_content, new_content)
	# Write contents to temporary files
	old_file = tempname()
	new_file = tempname()
	write(old_file, old_content)
	write(new_file, new_content)
	
	try
		diff_command = `git diff --no-index --color=always $old_file $new_file`
		output = IOBuffer()
		error_output = IOBuffer()
		
		process = run(pipeline(diff_command, stdout=output, stderr=error_output), wait=true)
		
		if process.exitcode != 0 && process.exitcode != 1
				# Exit code 1 is normal for Git diff when differences are found
				error_message = String(take!(error_output))
				@warn "Git diff error: $error_message"
				return "Error: Unable to generate diff view"
		end
		
		diff_output = String(take!(output))
		
		lines = split(diff_output, '\n')
		processed_lines = filter(line -> !startswith(line, "diff ") && 
																		 !startswith(line, "index ") && 
																		 !startswith(line, "--- ") && 
																		 !startswith(line, "+++ "), lines)
		
		return join(processed_lines, '\n')
	catch e
		@warn "Error running git diff: $e"
		return "Error: Unable to generate diff view"
	finally
		rm(old_file, force=true)
		rm(new_file, force=true)
	end
end


function display_file_diff(file_diff::FileDiff)
			println("File: $(file_diff.filename)")
			println("Diff:")
			println(create_git_diff_view(file_diff.old_content, file_diff.new_content))
end