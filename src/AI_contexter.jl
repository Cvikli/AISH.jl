
abstract type AbstractContextCreator end

@kwdef struct SimpleContexter <: AbstractContextCreator
    keep::Int = 7
end

function cut_history!(conv; keep=9)
    if keep < 0
        return conv.messages
    end
    conv.messages = conv.messages[max(end-keep+1,1):end]
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

