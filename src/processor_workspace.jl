
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

