using REPL
using REPL.LineEdit

function readline_improved()
    # Set up a prompt
    prompt = "➜ "

    # Create a custom keymap
    keymap = Dict{Any,Any}(
        # Enter key behavior
        '\r' => function (s,o...)
            if isempty(LineEdit.buffer(s))
                LineEdit.transition(s, :done)
                return :done
            end
            LineEdit.edit_insert(s, '\n')
            return nothing
        end,
        # Ctrl+D behavior
        '^D' => function (s,o...)
            if !isempty(LineEdit.buffer(s))
                LineEdit.edit_insert(s, "")
                return nothing
            else
                LineEdit.transition(s, :done)
                return :done
            end
        end
    )

    # Create a custom on_done function
    function on_done(s, buf, ok)
        if !ok
            return LineEdit.transition(s, :abort)
        end
        return LineEdit.transition(s, :done)
    end

    # Create a custom REPL mode
    mode = LineEdit.Prompt(prompt;
        prompt_prefix = "\e[36m",
        prompt_suffix = "\e[0m",
        keymap_dict = keymap,
        on_done = on_done
    )

    # Set up the terminal
    t = REPL.Terminals.TTYTerminal("", stdin, stdout, stderr)

    # Run the REPL mode
    line = LineEdit.prompt(t, mode, true)

    # Return the input as a string
    return line === nothing ? "" : String(line)
end