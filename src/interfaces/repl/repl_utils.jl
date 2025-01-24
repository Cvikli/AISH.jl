
# interface required functions.
get_flags_str(::Workflow) = " [unimplemented]"  # Base case for generic workflows
reset_flow!(::Workflow)   = @warn "Unimplemented."


@kwdef mutable struct PathCompletionProvider <: REPL.LineEdit.CompletionProvider
	modifiers::REPL.LineEdit.Modifiers=REPL.LineEdit.Modifiers()
end

REPL.LineEdit.complete_line(c::PathCompletionProvider, s::REPL.LineEdit.PromptState; kwargs...) = begin
	partial = REPL.beforecursor(s.input_buffer)
	full = REPL.LineEdit.input_string(s)

	if startswith(partial, "-p ")
			# Get the partial path being typed
			parts = split(partial[4:end], ' ', keepempty=false)
			current = isempty(parts) ? "" : last(parts)
			
			# Expand user path if needed
			expanded_current = expanduser(current)
			dir = isempty(expanded_current) ? pwd() : dirname(expanded_current)
			base = basename(expanded_current)
			# base = String(current) #basename(expanded_current)
			
			# Get completions if directory exists
			if isdir(dir)
					completions = String[]

					for entry in readdir(dir)
							if isdir(joinpath(dir, entry)) && startswith(entry, base)  # Case-insensitive comparison
									# Use normpath to handle ".." properly
									rel_path = isempty(dirname(current)) ? entry : joinpath(dirname(current), entry)
									push!(completions, normpath(rel_path) * "/")
							end
					end
					# completions = [t[length(dir)+2:end] for t in completions]
					return completions, String(current), !isempty(completions)
			end
	end
	return String[], "", false
end

