const ChatSH::String = "Orion"
const ainame::String = lowercase(ChatSH)
# AI name have to be short, transcriptable not ordinary common word.

const DATE_FORMAT_REGEX = r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:z|Z)?"
const DATE_FORMAT::String = "yyyy-mm-ddTHH:MM:SS.sssZ"

const MSG_FORMAT::Regex = r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+Z)?) \[(\w+), in: (\d+), out: (\d+), price: ([\d.]+), elapsed: ([\d.]+)\]: (.+)"s

const CONVERSATION_DIR = joinpath(@__DIR__, "..", "conversations")
const CONVERSATION_FILE_REGEX = Regex("^($(DATE_FORMAT_REGEX.pattern))_(?<sent>.*)_(?<id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\\.log\$")
mkpath(CONVERSATION_DIR)


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
const FILTERED_FOLDERS = ["spec", "specs", "examples", "docs", "python", "benchmarks", "node_modules", 
"conversations", "archived", "archive", ".git"]
const IGNORED_FILE_PATTERNS = [".log", "config.ini", "secrets.yaml", "Manifest.toml", ".gitignore", ".aiignore", ".aishignore", "Project.toml"] # , "README.md"

get_system() = strip(read(`uname -a`, String))
get_shell() = strip(read(`$(ENV["SHELL"]) --version`, String))

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

