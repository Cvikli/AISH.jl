
function print_project_tree(path::String)
	files = get_project_files(path)
	rel_paths = sort([relpath(f, path) for f in files])
	
	println("Project structure:")
	prev_parts = String[]
	for (i, file) in enumerate(rel_paths)
			parts = splitpath(file)
			
			# Find the common prefix with the previous file
			common_prefix_length = findfirst(j -> j > length(prev_parts) || parts[j] != prev_parts[j], 1:length(parts)) - 1
			
			# Print directories that are new in this path
			for j in (common_prefix_length + 1):(length(parts) - 1)
					print_tree_line(parts[1:j], j, i == length(rel_paths), false, rel_paths[i+1:end])
			end
			
			# Print the file (or last directory)
			print_tree_line(parts, length(parts), i == length(rel_paths), true, rel_paths[i+1:end])
			
			prev_parts = parts
	end
end

function print_tree_line(parts, depth, is_last_file, is_last_part, remaining_paths)
	prefix = ""
	for k in 1:(depth - 1)
			prefix *= any(p -> startswith(p, join(parts[1:k], "/")), remaining_paths) ? "│   " : "    "
	end
	
	symbol = is_last_file && is_last_part ? "└── " : "├── "
	println(prefix * symbol * parts[end] * (is_last_part ? "" : "/"))
end
function print_project_tree(state::AIState)
	print_project_tree(state.project_path)
end
