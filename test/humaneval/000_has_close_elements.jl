function has_close_elements(numbers::Vector{Float64}, threshold::Float64)::Bool
    for i in 1:length(numbers)
        for j in (i+1):length(numbers)
            if abs(numbers[i] - numbers[j]) < threshold
                return true
            end
        end
    end
    return false
end
