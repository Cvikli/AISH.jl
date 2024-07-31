# ai_server.jl
using HTTP
using JSON3

function handle_request(req::HTTP.Request)
	@show req
    # Add CORS headers
    headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ]

    if req.method == "OPTIONS"
        return HTTP.Response(200, headers)
    elseif req.method == "POST"
        body = JSON3.read(IOBuffer(HTTP.payload(req)))
        input_message = body.message

        # Simulate AI processing (replace with actual AI logic later)
        response = "AI responsesdse to: " * input_message

        return HTTP.Response(200, [headers..., "Content-Type" => "application/json"], JSON3.write(Dict("response" => response)))
    else
        return HTTP.Response(405, "Method Not Allowed")
    end
end

handle_interrupt(sig::Int32) = (println("\nExiting gracefully. Good bye! :)"); exit(0))
ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 2, @cfunction(handle_interrupt, Cvoid, (Int32,)))
HTTP.serve(handle_request, "0.0.0.0", 8000)