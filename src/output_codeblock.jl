

@kwdef mutable struct CodeBlock
	id::String=genid()
	type::Symbol=:NOTHING
	language::String
	file_path::String
	pre_content::String
	content::String=""
	run_results::Vector{String}=[]
end


codestr(cb) = if cb.type==:MODIFY return process_modify_command(cb.file_path, cb.content)
	elseif cb.type==:CREATE         return process_create_command(cb.file_path, cb.content)
	elseif cb.type==:DEFAULT        return cb.content
	else @assert false "not known type for $cb"
end

process_modify_command(file_path::String, content::String) = "meld $(file_path) <(cat <<'EOF'\n$(content)\nEOF\n)"
process_create_command(file_path::String, content::String) = "cat > $(file_path) <<'EOF'\n$(content)\nEOF"

preprocess(cb::CodeBlock) = cb.content = cb.type==:MODIFY ? improve_command_LLM(cb.pre_content) : cb.pre_content

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

