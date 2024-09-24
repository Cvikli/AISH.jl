
clearline() = print("\033[1\033[G\033[2K")

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))
nice_exit_handler() = ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,))) # Nice program exit for ctrl + c.



noop() = nothing
noop(_) = nothing
noop(_,_) = nothing


function progressing_spinner()
	stop_condition= Ref(false)
	p = ProgressUnknown("Progressing...", spinner=true)
	@async_showerr begin
			while !istaskdone(current_task()) && !stop_condition[]
					ProgressMeter.next!(p)  # Update spinner without incrementing progress
					sleep(0.05)
			end
	end
	stop_condition
end

is_really_empty(user_question) = isempty(strip(user_question))
