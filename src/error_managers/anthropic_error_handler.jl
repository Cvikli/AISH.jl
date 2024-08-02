using PromptingTools
using PromptingTools: role4render, AnthropicSchema
using PromptingTools: SystemMessage, UserMessage, AIMessage
using HTTP
using JSON

function safe_aigenerate(conversation; model, max_retries=3, return_all=false)
    for attempt in 1:max_retries
        try
            # Convert Message to AbstractChatMessage
            conv = [
                msg.role == :system ? SystemMessage(msg.content) :
                msg.role == :user ? UserMessage(msg.content) :
                msg.role == :ai ? AIMessage(msg.content) : UserMessage(msg.content)
                for msg in conversation
            ]
            return aigenerate(conv, model=model, return_all=return_all)
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
