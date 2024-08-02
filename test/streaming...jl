
function stream_anthropic_response(conversation; model="claude-3-5-sonnet-20240620", return_all=false)

	url = "https://api.anthropic.com/v1/messages"
	headers = [
			"Content-Type" => "application/json",
			"X-API-Key" => ENV["ANTHROPIC_API_KEY"],
			"anthropic-version" => "2023-06-01",
	]
	system_conversation_i = findfirst(m -> role4render(AnthropicSchema(), m) == "system", conversation)
	system_message = !isnothing(system_conversation_i) ? conversation[system_conversation_i].content : ""
	messages = [Dict("role" => role4render(AnthropicSchema(), m), "content" => m.content) for m in conversation if role4render(AnthropicSchema(), m) !== "system"]
	# display(messages)
	body = json(Dict(
			"messages" => messages,
			"system" => system_message,
			"model" => model,
			"max_tokens" => 256,
			"stream" => true
	))
	println("WORKING?")
	response_text = ""

	run(`curl https://api.anthropic.com/v1/messages \
	--header "x-api-key: $(ENV["ANTHROPIC_API_KEY"])" \
	--header "anthropic-version: 2023-06-01" \
	--header "content-type: application/json" \
	--data \
'{
 "model": "claude-3-5-sonnet-20240620",
 "max_tokens": 1024,
 "messages": [
		 {"role": "user", "content": "Hello, world"}
 ]
}'`)
	# io = open("test.txt", "w")
	# r = HTTP.request("POST", url, headers, body=body, response_stream=io)
	# close(io)
	# println("WORKING?")
	# println(read("get_data.txt", String))
	# println("WORKING?")
	# stream=IOBuffer()
	# HTTP.request("POST",url, headers=headers, body=JSON.json(body)) do stream

	# HTTP.open("POST", url, headers; ) do io
	#     write(io, body)
	#     @show "???????"
	#     @show keys(body)
	#     @show "?????"
	#     @show startread(io)
	#     @show "???"
	#     while !eof(io)
	#         @show readavailable(io)
	#     end
	# end


	# HTTP.open("POST", url, headers=headers) do stream
	#     println("WORKING?323")
	#     write(stream, body)
	#     println("WORKING?323adqd")
	#     r = startread(stream)
	#     @show r.status
	#     while !eof(stream)
	#         bytes = readavailable(stream)
	#     end
	#     # @show io
	#     # close(io)

	#     println("WORKING???")
	#     while !eof(stream)
	#         println("DATA: ---")
	#         println(String(readavailable(stream)))
	#     end

	#     println("WORKING?")
	# end

	# for line in eachline(stream)
	#     @show line
	#     if startswith(line, "data: ")
	#         data = JSON.parse(line[6:end])  # Remove "data: " prefix
	#         if data["type"] == "content_block_delta" && data["delta"]["type"] == "text_delta"
	#             chunk = data["delta"]["text"]
	#             print(chunk)
	#             flush(stdout)
	#             response_text *= chunk
	#         end
	#     end
	# end

	println()  # Add a newline at the end
	return response_text
end
