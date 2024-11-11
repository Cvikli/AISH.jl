
_conversation_id = Ref{String}("")

handle_interrupt(sig::Int32) = (println("\nExiting gracefully from conversation ($(_conversation_id[])). Good bye! :)"); exit(0))

function nice_exit_handler(conv::Union{String,Conversation,Session})
    global _conversation_id[] = conv isa String ? conv : conv isa Conversation ? "" : conv.id
    ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,)))
end

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")
