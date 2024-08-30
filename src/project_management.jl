

const path_separator="/"


is_project_file(lowered_file) = lowered_file in PROJECT_FILES || any(endswith(lowered_file, "." * ext) for ext in FILE_EXTENSIONS)
ignore_file(file) = any(endswith(file, pattern) for pattern in IGNORED_FILE_PATTERNS)

function parse_ignore_file(root, filename)
    ignore_path = joinpath(root, filename)
    !isfile(ignore_path) && return String[]
    patterns = String[]
    for line in eachline(ignore_path)
        line = strip(line)
        isempty(line) && continue
        startswith(line, '#') && continue
        push!(patterns, line)
    end
    return patterns
end

function parse_ignore_files(root)
    patterns = String[]
    for ignore_file in IGNORE_FILES
        ignore_path = joinpath(root, ignore_file)
        if isfile(ignore_path)
            append!(patterns, readlines(ignore_path))
        end
    end
    return patterns
end

function gitignore_to_regex(pattern)
    if pattern == "**"
        return r".*"
    end
    regex = replace(pattern, r"[.$^]" => s"\\\0")  # Escape special regex characters
    regex = replace(regex, r"\*\*/" => "(.*/)?")
    regex = replace(regex, r"\*\*" => ".*")
    regex = replace(regex, r"\*" => "[^/]*")
    regex = replace(regex, r"\?" => ".")
    regex = "^" * regex * "\$"
    return Regex(regex)
end

function is_ignored_by_patterns(file, ignore_patterns, root)
    root=="" && return false
    rel_path = relpath(file, root)
    for pattern in ignore_patterns
        regex = gitignore_to_regex(pattern)
        if occursin(regex, rel_path) || occursin(regex, basename(rel_path))
            return true
        end
        if endswith(pattern, '/') && startswith(rel_path, pattern[1:end-1])
            return true
        end
    end
    return false
end

function get_project_files(paths::Vector{String})
    all_files = String[]
    for path in paths
        append!(all_files, get_project_files(path))
    end
    return all_files
end
function get_project_files(path::String)
    files = String[]
    ignore_cache = Dict{String, Vector{String}}()
    ignore_stack = Pair{String, Vector{String}}[]
    
    for (root, dirs, files_in_dir) in walkdir(path, topdown=true)
        any(d -> d in FILTERED_FOLDERS, splitpath(root)) && (empty!(dirs); continue)
        
        # Read and cache ignore patterns for this directory
        if !haskey(ignore_cache, root)
            res = parse_ignore_files(root)
            if !isempty(res)
                ignore_cache[root] = res
                push!(ignore_stack, root => res)
            end
        end
        
        # Use the most recent ignore patterns
        ignore_patterns = isempty(ignore_stack) ? String[] : last(ignore_stack).second
        ignore_root = isempty(ignore_stack) ? "" : last(ignore_stack).first
        
        for file in files_in_dir
            file_path = joinpath(root, file)
            if is_project_file(lowercase(file)) && 
               !ignore_file(file_path) && 
               !is_ignored_by_patterns(file_path, ignore_patterns, ignore_root)
                push!(files, file_path)
            end
        end
        
        # Filter out ignored directories to prevent unnecessary recursion
        filter!(d -> !is_ignored_by_patterns(joinpath(root, d), ignore_patterns, ignore_root), dirs)
        
        # Remove ignore patterns from the stack when moving out of their directory
        while !isempty(ignore_stack) && !startswith(root, first(last(ignore_stack)))
            pop!(ignore_stack)
        end
    end
    return files
end
function get_all_project_files(path)
	all_files = get_project_files(path)
	result = map(file -> format_file_content(file), all_files)
	return join(result, "\n")
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



