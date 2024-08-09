using JSON
using HTTP
using Dates
using Boilerplate: @async_showerr

# stream_anthropic_response(ai_state::AIState; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256) = stream_anthropic_response(to_dict(ai_state); model, max_tokens)
# stream_anthropic_response(messages::Vector{Message}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256) = stream_anthropic_response(to_dict(messages); model, max_tokens)
stream_anthropic_response(prompt::String; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256) = stream_anthropic_response([Dict("role" => "user", "content" => prompt)]; model, max_tokens)
function stream_anthropic_response(msgs::Vector{Dict{String,String}}; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256)
    
    body = Dict("model" => model, "max_tokens" => max_tokens, "stream" => true)
    
    if msgs[1]["role"] == "system"
        body["system"] = msgs[1]["content"]
        body["messages"] = msgs[2:end]
    else
        body["messages"] = msgs
    end

    headers = Dict(
        "content-type" => "application/json",
        "x-api-key" => ENV["ANTHROPIC_API_KEY"],
        "anthropic-version" => "2023-06-01",
    )


    
    channel = Channel{String}(128)
    body = sprint() do output
    # @async_showerr (
        HTTP.open("POST", "https://api.anthropic.com/v1/messages", headers; status_exception=false) do io
        write(io, JSON.json(body))
        HTTP.closewrite(io)    # indicate we're done writing to the request
        HTTP.startread(io) 
        isdone = false
        while !eof(io) && !isdone
            chunk = String(readavailable(io))

            lines = String.(filter(!isempty, split(chunk, "\n")))
            for line in lines
                @show line
                # TODO !!! type == error !! HANDLE!!
                startswith(line, "data: ") || continue
                line == "data: [DONE]" && (isdone=true; break)
                data = JSON.parse(replace(line, r"^data: " => ""))
                # @show data
                get(data, "type", "") == "error" && (print(data["error"]); (isdone=true); break)
                if get(get(data, "delta", Dict()), "type", "") == "text_delta"
                    text = data["delta"]["text"]
                    put!(channel, text)
                    print(output, text)
                    # print(text)
                    flush(stdout)
                end
            end
        end
        HTTP.closeread(io)
    end;
    # close(channel)
    # )
end

    return body
end

res = stream_anthropic_response("Tell me a story")

#%%
res
#%%
ok = String(take!(res))
#%%

ok = String(take!(res))
#%%
ok