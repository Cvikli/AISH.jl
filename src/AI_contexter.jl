
abstract type AbstractContextCreator end

@kwdef struct SimpleContexter <: AbstractContextCreator
    keep::Int = 11
end

function cut_history!(conv; keep=13)
    if keep < 0
        return conv.messages
    end
    conv.messages = conv.messages[max(end-keep,1):end]
    @assert isempty(conv.messages) || conv.messages[1].role == :user "We made a cut which doesn't end with :user role message"
end

function prepare_user_message!(contexter::SimpleContexter, ai_state, question, shell_results::Dict{String, String})
    cut_history!(curr_conv(ai_state); keep=contexter.keep)
    formatted_results = format_shell_results(shell_results)
    formatted_results * question
end

function format_shell_results(shell_commands::Dict{String, String})
    result = ""
    for (code, output) in shell_commands
        shortened_code = get_shortened_code(code)
  
        result *= """## Previous shell results:
        ```sh
        $shortened_code
        ```
        ## Output:
        ```
        $output
        ```
        """
    end
    return result
end


function get_cache_setting(::AbstractContextCreator, conv)
    printstyled("WARNING: get_cache_setting not implemented for this contexter type. Defaulting to no caching.\n", color=:red)
    return nothing
end

function get_cache_setting(::SimpleContexter, conv)
    return nothing
end


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

