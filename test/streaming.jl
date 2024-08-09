using HTTP
using JSON

url = "https://api.anthropic.com/v1/messages"

body = Dict(
    "messages" => [
        Dict("content" => "Hi, tell me a story", "role" => "user"),
    ],
    "model" => "claude-3-5-sonnet-20240620",
    "max_tokens" => 256,
    "stream" => true,  # Set to true for streaming
)
headers = Dict(
    "content-type" => "application/json",
    "x-api-key" => ENV["ANTHROPIC_API_KEY"],
    "anthropic-version" => "2023-06-01",
)
response = HTTP.post(url, headers, JSON.json(body); verbose=1, status_exception=false)
if response.status == 200
    for line in eachline(IOBuffer(response.body))
        if startswith(line, "data: ")
          data = JSON.parse(line[6:end])
          if data["type"] == "content_block_delta" && data["delta"]["type"] == "text_delta"
            println(data["delta"]["text"])
            flush(stdout)
          end
        end
    end
else
    println("Error: ", response.status)
    println(String(response.body))
end



#%%
# ; response_stream=stdout
#%%
function stream_response(url, headers, body)
    HTTP.open("POST", url, headers, body=body) do response
        @show response
        for line in eachline((response))
            @show line
            if startswith(line, "data: ")
                data = JSON.parse(line[6:end])
                if data["type"] == "content_block_delta" && data["delta"]["type"] == "text_delta"
                    println(data["delta"]["text"])
                    flush(stdout)
                end
            end
        end
    end
end
stream_response(url, headers, JSON.json(body))


#%%

io=IOBuffer();
HTTP.post(url, headers, JSON.json(body); response_stream=io)
#%%
JSON.json(headers)

#%%

using JSON

function stream_anthropic_response(prompt::String; model::String="claude-3-5-sonnet-20240620", max_tokens::Int=256)
    # Construct the JSON payload
    payload = JSON.json(Dict(
        "model" => model,
        "messages" => [Dict("role" => "user", "content" => prompt)],
        "max_tokens" => max_tokens,
        "stream" => true
    ))

    # Construct the curl command
    cmd = `curl -s https://api.anthropic.com/v1/messages
        -H "anthropic-version: 2023-06-01"
        -H "content-type: application/json"
        -H "x-api-key: $(ENV["ANTHROPIC_API_KEY"])"
        -d $payload`
    # Open a pipe to the command
    open(cmd, "r") do io
        # Read and process the streaming output
        for line in eachline(io)
            # Skip empty lines
            isempty(strip(line)) && continue

            # Remove "data: " prefix if present
            if startswith(line, "data: ")
                line = replace(line, r"^data: " => "")
                # @show line
                data = JSON.parse(line)
                # @show data
                
                # Check for the [DONE] message
                line == "[DONE]" && break
                if data["type"] == "content_block_delta" && data["delta"]["type"] == "text_delta"
                    isempty(strip(data["delta"]["text"])) && continue
                    # print(now())
                    # print("  ")
                    print(data["delta"]["text"])
                    flush(stdout)
                end
            else 
                # println(line)
            end 
            # Parse the JSON response
        end
    end
    println()  # Add a newline at the end for cleaner output
end
