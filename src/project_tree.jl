
function print_project_tree(paths::Vector{String})
	print_project_tree.(paths)
end
function print_project_tree(path::String)
	println("Project structure: $path")
	files = get_project_files(path)
	rel_paths = sort([relpath(f, path) for f in files])
	
	prev_parts = String[]
	for (i, file) in enumerate(rel_paths)
			parts = splitpath(file)
			
			# Find the common prefix with the previous file
			common_prefix_length = findfirst(j -> j > length(prev_parts) || parts[j] != prev_parts[j], 1:length(parts)) - 1
			
			# Print directories that are new in this path
			for j in (common_prefix_length + 1):(length(parts) - 1)
					print_tree_line(parts[1:j], j, i == length(rel_paths), false, rel_paths[i+1:end])
			end
			
			# Print the file (or last directory) with size information
			print_tree_line(parts, length(parts), i == length(rel_paths), true, rel_paths[i+1:end], joinpath(path, file))
			
			prev_parts = parts
	end
end

function print_tree_line(parts, depth, is_last_file, is_last_part, remaining_paths, full_path="")
	prefix = ""
	for k in 1:(depth - 1)
			prefix *= any(p -> startswith(p, join(parts[1:k], "/")), remaining_paths) ? "│   " : "    "
	end
	
	symbol = is_last_file && is_last_part ? "└── " : "├── "
	name = parts[end]
	
	if !isempty(full_path) && isfile(full_path)
		size_chars = count(c -> !isspace(c), read(full_path, String))
		if size_chars > 10000
			size_str = format_file_size(size_chars)
			color = size_chars > 20000 ? "\e[31m" : "" # Red color for files over 20k chars
			reset = size_chars > 20000 ? "\e[0m" : ""
			println("$prefix$symbol$name $color($size_str)$reset")
		else
			println("$prefix$symbol$name")
		end
	else
		println("$prefix$symbol$name$(is_last_part ? "" : "/")")
	end
end

function format_file_size(size_chars)
	if size_chars < 1000
		return "$(size_chars) chars"
	else
		return "$(round(size_chars / 1000, digits=2))k chars"
	end
end

print_project_tree(state::AIState) = print_project_tree(curr_conv(state).rel_project_paths)
