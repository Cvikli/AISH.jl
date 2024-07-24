using PromptingTools

function safe_aigenerate(conversation; model, max_retries=3)
    for attempt in 1:max_retries
        try
            return aigenerate(conversation, model=model)
        catch e
            if attempt < max_retries
                sleep_time = 2^attempt
                @warn "Error occurred. Retrying in $sleep_time seconds... (Attempt $attempt of $max_retries)"
                sleep(sleep_time)
            else
                @error "Failed after $max_retries attempts: $(e)"
                rethrow(e)
            end
        end
    end
end
