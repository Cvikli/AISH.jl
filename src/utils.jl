
handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))
nice_exit_handler() = ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,))) # Nice program exit for ctrl + c.

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")

