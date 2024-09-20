

@kwdef mutable struct CodeBlock
    id::String = ""  # We'll set this in the constructor
    type::Symbol = :NOTHING
    language::String
    file_path::String
    pre_content::String
    content::String = ""
    run_results::Vector{String} = []
end

# Constructor to set the id based on pre_content hash
function CodeBlock(type::Symbol, language::String, file_path::String, pre_content::String, content::String = "", run_results::Vector{String} = [])
    id = bytes2hex(sha256(pre_content))
    CodeBlock(id, type, language, file_path, pre_content, content, run_results)
end

codestr(cb) = if cb.type==:MODIFY return process_modify_command(cb.file_path, cb.content)
    elseif cb.type==:CREATE         return process_create_command(cb.file_path, cb.content)
    elseif cb.type==:DEFAULT        return cb.content
    else @assert false "not known type for $cb"
end

process_modify_command(file_path::String, content::String) = "meld $(file_path) <(cat <<'EOF'\n$(content)\nEOF\n)"
process_create_command(file_path::String, content::String) = "cat > $(file_path) <<'EOF'\n$(content)\nEOF"

preprocess(cb::CodeBlock) = (cb.content = cb.type==:MODIFY ? improve_command_LLM(cb) : cb.pre_content; cb)

function get_shortened_code(code::String, head_lines::Int=4, tail_lines::Int=3)
    lines = split(code, '\n')
    total_lines = length(lines)
    
    if total_lines <= head_lines + tail_lines
            return code
    else
            head = join(lines[1:head_lines], '\n')
            tail = join(lines[end-tail_lines+1:end], '\n')
            return "$head\n...\n$tail"
    end
end

