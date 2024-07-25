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


CopyThis is the first line.
<<<<<<< HEAD
This line was changed in the main branch.
=======
This line was changed in the feature branch.
>>>>>>> feature-branch
This is the third line.

could you remove kdiff3 from the merge tool options?
#%%
run(`bash -c 'diff --help'`)
x="  code_content "
typeof(strip(x
))
#%%

run(`bash -c "which meld"`)
