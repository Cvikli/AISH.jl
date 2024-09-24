
@kwdef mutable struct Workspace
	project_paths::Vector{String}=String[]
	rel_project_paths::Vector{String}=String[]
	common_path::String=""
end

CreateWorkspace(project_paths::Vector{String}=String[]) = begin
		common_path, rel_project_paths = find_common_path_and_relatives(project_paths)
    Workspace(project_paths, rel_project_paths, common_path)
end


set_project_path(path::String) = path !== "" && (cd(path); println("Project path initialized: $(path)"))
set_project_path(w::Workspace) = set_project_path(w.common_path)
set_project_path(w::Workspace, paths) = begin
    w.common_path, w.rel_project_paths = find_common_path_and_relatives(paths)
    set_project_path(w)
end


function find_common_path_and_relatives(paths)
	isempty(paths) && return "", String[]
	length(paths)==1 && return abspath(paths[1]), ["."]
	
	abs_paths = abspath.(paths)
	common_prefix = commonprefix(abs_paths)
	common_prefix = endswith(common_prefix, path_separator) ? common_prefix : common_prefix * path_separator
	
	relative_paths = relpath.(abs_paths, common_prefix)
	
	return common_prefix, relative_paths
end

function commonprefix(paths)
	splitted_paths = splitpath.(paths)
	for i in 1:100
			!allequal(p[i] for p in splitted_paths) && return joinpath(splitted_paths[1][1:i-1])
	end
	return paths[1]
end


print_project_tree(paths::Vector{String}; show_tokens::Bool=false) = print_project_tree.(paths; show_tokens)
print_project_tree(w::Workspace;          show_tokens::Bool=false) = print_project_tree(w.rel_project_paths; show_tokens)
print_project_tree(path::String;          show_tokens::Bool=false) = begin
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
        
        # Print the file (or last directory) with token count
        print_tree_line(parts, length(parts), i == length(rel_paths), true, rel_paths[i+1:end], joinpath(path, file), show_tokens=show_tokens)
        
        prev_parts = parts
    end
end

function print_tree_line(parts, depth, is_last_file, is_last_part, remaining_paths, full_path=""; show_tokens::Bool=false)
	prefix = ""
	for k in 1:(depth - 1)
			prefix *= any(p -> startswith(p, join(parts[1:k], "/")), remaining_paths) ? "│   " : "    "
	end
	
	symbol = is_last_file && is_last_part ? "└── " : "├── "
	name = parts[end]

	
	if !isempty(full_path) && isfile(full_path)
		full_file = read(full_path, String)
		name *= show_tokens ? " ($(count_tokens(full_file)))" : ""
		size_chars = count(c -> !isspace(c), full_file)
		if size_chars > 10000
			size_str = format_file_size(size_chars)
			color, reset = size_chars > 20000 ? ("\e[31m", "\e[0m") : ("", "") # Red color for files over 20k chars
			println("$prefix$symbol$name $color($size_str)$reset")
		else
			println("$prefix$symbol$name")
		end
	else
		println("$prefix$symbol$name$(is_last_part ? "" : "/")")
	end
end

format_file_size(size_chars) = return (size_chars < 1000 ? "$(size_chars) chars" : "$(round(size_chars / 1000, digits=2))k chars")

