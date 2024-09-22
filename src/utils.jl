
noop(_) = nothing
noop(_,_) = nothing

clearline() = print("\033[1\033[G\033[2K")

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")

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
