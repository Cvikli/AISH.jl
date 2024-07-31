using HTTP
using JSON

url = "https://api.anthropic.com/v1/messages"

body = Dict(
    "messages" => [
        Dict("content" => "Hi, tell me a very short story", "role" => "user"),
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
        for line in eachline(BufferedInputStream(response::HTTP.Stream))
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