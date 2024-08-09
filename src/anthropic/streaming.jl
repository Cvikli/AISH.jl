using JSON
using HTTP
using Dates
using Boilerplate: @async_showerr

stream_anthropic_response(ai_state::AIState; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256) = stream_anthropic_response(to_dict(ai_state); model, max_tokens)
stream_anthropic_response(messages::Vector{Message}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256) = stream_anthropic_response(to_dict(messages); model, max_tokens)
stream_anthropic_response(prompt::String; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256) = stream_anthropic_response([Dict("role" => "user", "content" => prompt)]; model, max_tokens)
function stream_anthropic_response(msgs::Vector{Dict{String,String}}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256)
    
    body = Dict("model" => model, "max_tokens" => max_tokens, "stream" => true)
    
    if msgs[1]["role"] == "system"
        body["system"] = msgs[1]["content"]
        body["messages"] = msgs[2:end]
    else
        body["messages"] = msgs
    end

    channel = Channel{String}(128)
    apikey = ENV["ANTHROPIC_API_KEY"]
    cmd = `curl -sS https://api.anthropic.com/v1/messages \
    -X POST \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -H "x-api-key: $apikey" \
    -d $(JSON.json(body))`
    # @show cmd
    @async_showerr ( 
        for line in eachline(pipeline(cmd))
            # TODO !!! type == error !! HANDLE!!
            startswith(line, "data: ") || continue
            data = JSON.parse(replace(line, r"^data: " => ""))
            data == "[DONE]" && break
            
            if get(get(data, "delta", Dict()), "type", "") == "text_delta"
                text = data["delta"]["text"]
                put!(channel, text)
                # print(text)
                flush(stdout)
            end
        end;
        # sleep(6);
        close(channel)
    )

    return channel
end