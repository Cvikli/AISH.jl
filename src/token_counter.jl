
function count_tokens(text::String)
    tokens = String[]
    current_token = ""
    for char in text
        if isletter(char) || isnumeric(char)
            current_token *= char
        else
            if !isempty(current_token)
                push!(tokens, current_token)
                current_token = ""
            end
            if !isspace(char)
                push!(tokens, string(char))
            end
        end
    end
    if !isempty(current_token)
        push!(tokens, current_token)
    end
    
    # Handle contractions and special cases
    final_tokens = String[]
    for token in tokens
        if startswith(token, "'")
            push!(final_tokens, token)
        else
            subtokens = split(token, r"(['-])")
            for (i, subtoken) in enumerate(subtokens)
                if !isempty(subtoken)
                    if i > 1 && subtokens[i-1] in ["'", "-"]
                        final_tokens[end] *= subtoken
                    else
                        push!(final_tokens, subtoken)
                    end
                end
            end
        end
    end
    
    # Split long tokens
    max_token_length = 50  # Adjust this value as needed
    split_tokens = String[]
    for token in final_tokens
        if length(token) > max_token_length
            chunks = [token[i:min(i+max_token_length-1, end)] for i in 1:max_token_length:length(token)]
            append!(split_tokens, chunks)
        else
            push!(split_tokens, token)
        end
    end
    
    return length(split_tokens)
end

