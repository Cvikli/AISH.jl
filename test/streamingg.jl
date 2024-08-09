using HTTP
using JSON

body = Dict(
    "messages" => [
        Dict("content" => "Hi, tell me a longer story", "role" => "user"),
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
HTTP.open("POST", "https://api.anthropic.com/v1/messages", headers; status_exception=false) do io
	write(io, JSON.json(body))
	HTTP.closewrite(io)    # indicate we're done writing to the request
	HTTP.startread(io) 
	while !eof(io)
		println(String(readavailable(io)))
	end
	HTTP.closeread(io)
end


@show "ok";


#%%


function request_body_live(url; input, headers, streamcallback, kwargs...)
	resp = nothing

	body = sprint() do output
			resp = HTTP.open("POST", url, headers) do stream
					body = String(take!(input))
					write(stream, body)

					HTTP.closewrite(stream)    # indicate we're done writing to the request

					r = HTTP.startread(stream) # start reading the response
					isdone = false

					while !eof(stream) || !isdone
							# Extract all available messages
							masterchunk = String(readavailable(stream))

							# Split into subchunks on newlines.
							# Occasionally, the streaming will append multiple messages together,
							# and iterating through each line in turn will make sure that
							# streamingcallback is called on each message in turn.
							chunks = String.(filter(!isempty, split(masterchunk, "\n")))

							# Iterate through each chunk in turn.
							for chunk in chunks
									if occursin(chunk, "data: [DONE]")  # TODO - maybe don't strip, but instead us a regex in the endswith call
											isdone = true
									end

									# call the callback (if present) on the latest chunk
									if !isnothing(streamcallback)
											streamcallback(chunk)
									end

									# append the latest chunk to the body
									print(output, chunk)
							end
					end
					HTTP.closeread(stream)
			end
	end

	return resp, body
end