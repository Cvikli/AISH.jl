const ChatSH::String = "Orion"
const ainame::String = lowercase(ChatSH)
const CONVERSATION_DIR = joinpath(@__DIR__, "..", "conversation")
mkpath(CONVERSATION_DIR)


const IGNORE_FILES = [".gitignore", ".aiignore", ".aishignore"]
const MAX_TOKEN = 4096 # note this should be model specific later on! Note for not streaming the limit can be higher!!???


const PROJECT_FILES = [
    "Dockerfile", "docker-compose.yml", "Makefile", "LICENSE",  
    "README.md", 
    "Gemfile", "Cargo.toml"# , "Project.toml"
]

const FILE_EXTENSIONS = [
    "toml", "ini", "cfg", "conf", "sh", "bash", "zsh", "fish",
    "html", "css", "scss", "sass", "less", "js", "jsx", "ts", "tsx", "php", "vue", "svelte",
    "py", "pyw", "ipynb", "rb", "rake", "gemspec", "java", "kt", "kts", "groovy", "scala",
    "clj", "c", "h", "cpp", "hpp", "cc", "cxx", "cs", "csx", "go", "rs", "swift", "m", "mm",
    "pl", "pm", "lua", "hs", "lhs", "erl", "hrl", "ex", "exs", "lisp", "lsp", "l", "cl",
    "fasl", "jl", "r", "R", "Rmd", "mat", "asm", "s", "dart", "sql", "md", "markdown",
    "rst", "adoc", "tex", "sty", "gradle", "sbt", "xml"
]
const FILTERED_FOLDERS = ["spec", "specs", "examples", "docs", "python", "benchmarks", "node_modules", 
"conversations", "archived", ".git"]
const IGNORED_FILE_PATTERNS = [".log", "config.ini", "secrets.yaml", "Manifest.toml", ".gitignore", ".aiignore", ".aishignore", "Project.toml"] # , "README.md"

get_system() = strip(read(`uname -a`, String))
get_shell() = strip(read(`$(ENV["SHELL"]) --version`, String))

function set_project_path(path)
    global PROJECT_PATH = path
    PROJECT_PATH !== "" && (cd(PROJECT_PATH); PROJECT_PATH = pwd(); println("Project path initialized: $(PROJECT_PATH)"))
    return PROJECT_PATH
end

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

function get_project_files(path)
    files = String[]
    ignore_cache = Dict{String, Vector{String}}()
    ignore_stack = Pair{String, Vector{String}}[]
    
    for (root, dirs, files_in_dir) in walkdir(path)
        any(d -> d in FILTERED_FOLDERS, splitpath(root)) && continue
        
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

function format_file_content(file)
    content = read(file, String)
    relative_path = relpath(file, pwd())

    ext = lowercase(splitext(file)[2])
    comment_map = Dict(
        ".jl" => ("#", ""), ".py" => ("#", ""), ".sh" => ("#", ""), ".bash" => ("#", ""), ".zsh" => ("#", ""), ".r" => ("#", ""), ".rb" => ("#", ""),
        ".js" => ("//", ""), ".ts" => ("//", ""), ".cpp" => ("//", ""), ".c" => ("//", ""), ".java" => ("//", ""), ".cs" => ("//", ""), ".php" => ("//", ""), ".go" => ("//", ""), ".rust" => ("//", ""), ".swift" => ("//", ""),
        ".html" => ("<!--", "-->"), ".xml" => ("<!--", "-->")
    )

    comment_prefix, comment_suffix = get(comment_map, ext, ("#", ""))

    return """
    $(comment_prefix)File Name: $(relative_path)$(comment_suffix)
    $(comment_prefix)Content: $(comment_suffix)
    $content
    ========================================
    """
end
function get_all_project_files(path, question="")
    all_files = get_project_files(path)
    result = map(file -> format_file_content(file), all_files)
    return join(result, "\n")
end
project_ctx = get_all_project_files

