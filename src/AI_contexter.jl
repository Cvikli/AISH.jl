abstract type AbstractContextCreator end


@kwdef struct SimpleContexter <: AbstractContextCreator
    keep::Int = 11
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
