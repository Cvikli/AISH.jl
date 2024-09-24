
@kwdef mutable struct Workspace
	project_paths::Vector{String}=[]
	rel_project_paths::Vector{String}=[]
	common_path::String=""
end

CreateWorkspace(project_paths::Vector{String}=[]) = begin
		common_path, rel_project_paths = find_common_path_and_relatives(project_paths)
    Workspace(project_paths, rel_project_paths, common_path)
end
