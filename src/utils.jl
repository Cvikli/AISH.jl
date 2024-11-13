
_conversation_id = Ref{String}("")
_in_loop = Ref{Bool}(false)

handle_interrupt(sig::Int32) = begin
    if _in_loop[]
        println("\nInterrupting current workflow...")
		_in_loop[] = false 
        ccall(:uv_kill, Cint, (Cint, Cint), getpid(), 2)  # Send SIGINT
    else
        println("\nExiting gracefully from conversation ($(_conversation_id[])). Good bye! :)")
        exit(0)
    end
    return
end

function nice_exit_handler(conv::Union{String,Conversation,Session})
    global _conversation_id[] = conv isa String ? conv : conv isa Conversation ? "" : conv.id
    ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,)))
end

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")
