
# const ChatSH::String = "Vex"
# const ChatSH::String = "Zono"
# const ChatSH::String = "Pixel"
const ChatSH::String = "Koda"
const ainame::String = lowercase(ChatSH)

PROJECT_PATH::String = "."
set_project_path(path) = (global PROJECT_PATH = path)

get_system()                   = strip(read(`uname -a`, String))
get_shell()                    = strip(read(`$(ENV["SHELL"]) --version`, String))
get_pwd()                      = strip(pwd())


const PROJECT_FILES = [
    "Dockerfile", "docker-compose.yml", "Makefile", "README.md", "LICENSE", ".gitignore",
    "Gemfile", "Cargo.toml", "Project.toml"
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
const FILTERED_FOLDERS = ["test", "tests", "spec", "specs", "examples", "docs"]
const IGNORED_FILE_PATTERNS = [".log", "config.ini", "secrets.yaml", "Manifest.toml"]

is_project_file(lowered_file) = lowered_file in PROJECT_FILES || any(endswith(lowered_file, "." * ext) for ext in FILE_EXTENSIONS)

get_project_files(path=PROJECT_PATH) = [joinpath(root, file) for (root, _, files) in walkdir(path) for file in files if is_project_file(lowercase(basename(file)))]

filter_gitignore_files(all_files, path=".") = cd(path) do
  filter(file -> !success(`git check-ignore -q $file`), all_files)
end

ignore_folder(file) = any(startswith(file, folder) for folder in FILTERED_FOLDERS)
ignore_file(file) = any(endswith(file, pattern) for pattern in IGNORED_FILE_PATTERNS)

# TODO make sure the # is a comment in that specific language!!
format_file_content(path, file) = """

============================
# File: $path/$file
$(read(joinpath(path, file), String))
"""

function get_all_project_with_URIs(path=PROJECT_PATH)
  all_files = get_project_files(path)
  files = filter_gitignore_files(all_files, path)
  filtered_files = filter(f -> !ignore_folder(f) && !ignore_file(f), files)
  println.(filtered_files)
  result = map(file -> format_file_content(path, file), filtered_files)
  return join(result, "\n")
end



# 

