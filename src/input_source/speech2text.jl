using Pipe

#TODO this should work like it return with the recognized prompt.

function speech2text(AI)
    cmd = `python3 python/main.py`
    
    @pipe cmd |> open(_; read=true) do process
        for line in eachline(process) AI(line) end
    end 
end