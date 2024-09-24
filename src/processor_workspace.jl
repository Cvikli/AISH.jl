
@kwdef mutable struct Workspace
	project_paths::Vector{String}=[]
	rel_project_paths::Vector{String}=[]
	common_path::String=""
end

CreateWorkspace(project_paths::Vector{String}=[]) = begin
		common_path, rel_project_paths = find_common_path_and_relatives(project_paths)
    Workspace(project_paths, rel_project_paths, common_path)
end


set_project_path(path::String) = path !== "" && (cd(path); println("Project path initialized: $(path)"))
set_project_path(w::Workspace) = set_project_path(w.common_path)
set_project_path(w::Workspace, paths) = begin
    w.common_path, w.rel_project_paths = find_common_path_and_relatives(paths)
    set_project_path(w)
end

