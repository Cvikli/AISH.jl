using PromptingTools
using HTTP

function safe_aigenerate(conversation; model, max_retries=3)
    for attempt in 1:max_retries
        try
            return aigenerate(conversation, model=model)
        catch e
            if e isa HTTP.StatusError && e.status in [500, 529]
                if attempt < max_retries
                    sleep_time = 2^attempt
                    @warn "Server error (status $(e.status)). Retrying in $sleep_time seconds... (Attempt $attempt of $max_retries)"
                    sleep(sleep_time)
                else
                    @error "Failed after $max_retries attempts due to persistent server errors."
                    rethrow(e)
                end
            else
                @error "Unhandled error occurred: $(e)"
                rethrow(e)
            end
        end
    end
end
