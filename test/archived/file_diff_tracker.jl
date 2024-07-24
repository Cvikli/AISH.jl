using Base: @kwdef
using Dates

@kwdef struct FileDiff
    filename::String
    new_filename::String
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
function generate_file_diff(code_block)
	filename, new_content = extract_filename_and_content(code_block)
	isnothing(filename) || isnothing(new_content) && return nothing
	
	old_content = isfile(filename) ? read(filename, String) : ""
	
	# Generate a new filename with a timestamp and "upgraded" tag
	dir, base = splitdir(filename)
	name, ext = splitext(base)
	timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
	new_filename = joinpath(dir, "$(name)_upgraded_$(timestamp)$(ext)")
	
	# Write the new content to the new file
	write(new_filename, new_content)
	
	FileDiff(filename=filename, new_filename=new_filename, old_content=old_content, new_content=new_content)
end

function open_external_merge_tool(file_diff::FileDiff)
	merge_tools = [
		("VS Code", Sys.iswindows() ? "code.cmd" : "code", `--wait --diff`),
		("Meld", "/usr/bin/meld", ``),
		("Vimdiff", "vimdiff", ``),
		("Custom", get(ENV, "MERGE_TOOL", ""), ``)
	]
	
	for (tool_name, command, args) in merge_tools
		!success(`which $command`) && continue
		println("Opening merge view in $tool_name...")
		run(`$command $args $(file_diff.new_filename) $(file_diff.filename)`)
		return
	end
	
	println("No merge tool available. Please compare the files manually:")
	println("Original file: $(file_diff.filename)")
	println("Proposed changes: $(file_diff.new_filename)")
end

function display_file_diff(file_diff::FileDiff)
    println("File: $(file_diff.filename)")
    open_external_merge_tool(file_diff)
end
