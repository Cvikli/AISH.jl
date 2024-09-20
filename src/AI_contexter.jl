abstract type AbstractContextCreator end


@kwdef struct SimpleContexter <: AbstractContextCreator
    keep::Int = 11
end

const IGNORE_FILES = [".gitignore", ".aishignore"]
const MAX_TOKEN = 8192 

const PROJECT_FILES = [
    "Dockerfile", "docker-compose.yml", "Makefile", "LICENSE", "package.json", 
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
const FILTERED_FOLDERS = ["spec", "specs", "examples", "docs", "dist", "python", "benchmarks", "node_modules", 
"conversations", "archived", "archive", "test_cases", ".git"]
const IGNORED_FILE_PATTERNS = [".log", "config.ini", "secrets.yaml", "Manifest.toml", ".gitignore", ".aiignore", ".aishignore", "Project.toml"] # , "README.md"



function cut_history!(conv; keep=13)
    length(conv.messages) <= keep && return conv.messages
    
    start_index = max(1, length(conv.messages) - keep + 1)
    start_index += (conv.messages[start_index].role == :assistant)
    
    conv.messages = conv.messages[start_index:end]
end

function prepare_user_message!(contexter::SimpleContexter, ai_state, question, shell_results::AbstractDict{String, CodeBlock})
    cut_history!(curr_conv(ai_state); keep=contexter.keep)
    formatted_results = format_shell_results(shell_results)
    formatted_results * question
end

function format_shell_results(shell_commands::AbstractDict{String, CodeBlock})
    result = "<ShellRunResults>"
    for (code, output) in shell_commands
        shortened_code = get_shortened_code(code)
  
        result *= """
        <sh_script shortened>
        $shortened_code
        <!sh_script>
        <sh_output>
        $output
        </sh_output>
        """
    end
    result *= "</ShellRunResults>"
    return result
end


function get_cache_setting(::AbstractContextCreator, conv)
    printstyled("WARNING: get_cache_setting not implemented for this contexter type. Defaulting to no caching.\n", color=:red)
    return nothing
end

get_cache_setting(::SimpleContexter, conv) = return nothing


project_ctx(path) = """
The codebase you are working on:
================================
$(get_all_project_files(path))
================================
This is the latest version of the codebase, chats after these can only hold same or older versions only. If something is not like you proposed that is probably that change was not accepted, or there were manual edits in the code, which we should keep probably.
"""
projects_ctx(paths::Vector{String}) = """
The codebase you are working on:
================================
$(join(get_all_project_files.(paths),"\n================================\n"))
================================
This is the latest version of the codebase, chats after these can only hold same or older versions only. If something is not like you proposed that is probably that change was not accepted, or there were manual edits in the code, which we should keep probably.
"""

get_codebase_ctx(question, path, ) = """
The codebase you are working on:
================================
$(project_ctx(path, question))
================================
This is the latest version of the codebase, chats after these can only hold same or older versions only. If something is not like you proposed that is probably that change was not accepted, or there were manual edits in the code, which we should keep probably.
"""


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
    File: $(relative_path)
    ```
    $content
    ```
    """
end

