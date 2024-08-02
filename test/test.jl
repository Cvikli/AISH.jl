using Statistics

function weather_data_analyzer(temps::Vector{<:Real})
    if isempty(temps)
        return (; average=nothing, max=nothing, min=nothing, trend=nothing)
    end

    avg = mean(temps)
    max_temp = maximum(temps)
    min_temp = minimum(temps)

    # Calculate the trend
    if length(temps) > 1
        first_half = temps[1:div(end, 2)]
        second_half = temps[div(end, 2)+1:end]
        
        first_half_mean = mean(first_half)
        second_half_mean = mean(second_half)
        
        if isapprox(first_half_mean, second_half_mean, atol=0.1)
            trend = :stable
        elseif second_half_mean > first_half_mean
            trend = :increasing
        else
            trend = :decreasing
        end
    else
        trend = :stable
    end

    return (; average=avg, max=max_temp, min=min_temp, trend=trend)
end
#%%
```

This function...

```julia
#%%
temps = [20.5, 21.0, 22.5, 23.0, 22.0, 21.5, 23.5]
result = weather_data_analyzer(temps)
println(result)
#%%
```

This will output something like:
```
(average = 22.0, max = 23.5, min = 20.5, trend = :increasing)
```

And for an empty list:

```julia
#%%

empty_temps = Float64[]
empty_result = weather_data_analyzer(empty_temps)
println(empty_result)
#%%
```

This will output:
```
(average = nothing, max = nothing, min = nothing, trend = nothing)

#%%

try
cmd = """
read -q "?continue? (y) " && cat > README_FINAL.md <<-"EOL"
content
EOL
"""
run(`zsh -c $cmd`)
catch error
    @show error
    @show error.procs
    @show error.procs[1].exitcode
    ProcessFailedException
    error_output = strip(sprint(showerror, error))
    @warn("Error occurred during execution: $error_output")
  end

#%%
using REPL
using REPL.LineEdit
xx=IOBuffer()
# isempty(take!(xx))
position(xx)
input = String(xx)


#%!

using REPL
using REPL.LineEdit

function readline_improved()
    # Set up a prompt string
    prompt_str = "➜ "

    # Create a custom keymap
    keymap = Dict{Any,Any}(
        '\r' => function (s,o...)
            if position(LineEdit.buffer(s)) == 0
                return :done
            end
            return :done
        end,
        Char(4) => function (s,o...)
            if position(LineEdit.buffer(s))  > 0
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
    return strip(input)
end

