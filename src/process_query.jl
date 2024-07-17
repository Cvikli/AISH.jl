
process_question(state) = begin
	println("Thinking...")
	assistant_message = aigenerate(state.conversation, model=state.model)
	push!(state.conversation, assistant_message)
	# print("\e[1A\e[2K")  # Move cursor up and clear line
	println(assistant_message.content)
	println()
	try
		code = extract_code(assistant_message.content)

		if code !== nothing
			println("\e[31mPress enter to execute, or 'N' to cancel.\e[0m")
			answer = readline()
			if lowercase(answer) == "n"
				state.last_output = "Command execution skipped."
				println(state.last_output)
			else
				try
					state.last_output = strip(read(`bash -c $code`, String))
					println("\e[2m$(state.last_output)\e[0m")
				catch error
					state.last_output = strip(sprint(showerror, error))
					println("\e[2m$(state.last_output)\e[0m")
					@warn("DANGEROUS  AS no backtrace is printed here!!")
				end
			end
		else
			state.last_output = ""
		end
	catch error
		last_output = strip(sprint(showerror, error))
		println("Error: $(last_output)")
		showerror(stdout, error, catch_backtrace())
	end
	return
end
