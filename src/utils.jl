_interrupt_handler = Ref{Function}((sig::Int32) -> nothing)
handle_interrupt(sig::Int32, id::String) = (println("\nExiting gracefully from conversation $id. Good bye! :)"); exit(0))
function nice_exit_handler(conv::Union{Conversation,ConversationX})
    global _interrupt_handler
    id = conv isa Conversation ? "" : conv.id
    _interrupt_handler[] = (sig::Int32) -> handle_interrupt(sig, id)
    ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(_interrupt_handler[], Cvoid, (Int32,)))
end

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")

