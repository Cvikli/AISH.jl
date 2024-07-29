using REPL
using REPL.LineEdit

function readline_improved()
    # Set up a prompt string
    prompt_str = "➜ "

    # Create a custom keymap
    keymap = Dict{Any,Any}(
        '\r' => function (s,o...)
            if isempty(LineEdit.buffer(s))
                return :done
            end
            return :done
        end,
        Char(4) => function (s,o...)
            if !isempty(LineEdit.buffer(s))
                LineEdit.edit_insert(s, "")
                return nothing
            else
                return :done
            end
        end
    )

    # Create a custom on_done function
    function on_done(s, buf, ok)
        if !ok
            return :abort
        end
        return String(buf)
    end

    # Create a custom REPL mode
    mode = LineEdit.Prompt(
        prompt_str,
        prompt_prefix = "\e[36m",
        prompt_suffix = "\e[0m",
        keymap_dict = keymap,
        on_done = on_done
    )

    # Set up the terminal
    if isdefined(Base, :active_repl)
        repl = Base.active_repl
        terminal = repl.t
    else
        terminal = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)
    end

    # Create a ModalInterface with our single mode
    mi = ModalInterface([mode])

    s = LineEdit.init_state(terminal, mi)
    LineEdit.edit_insert(s, "")  # Ensure the buffer is initialized
    LineEdit.prompt!(terminal, mi, s)

    # Get the input from the buffer
    input = String(take!(LineEdit.buffer(s)))
    @show input

    # Return the input as a string
    @assert false
    return strip(input)
end