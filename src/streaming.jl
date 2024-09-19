
using PromptingTools: StreamCallback, StreamChunk, AbstractStreamCallback, AbstractPromptSchema, OpenAISchema, AbstractStreamFlavor, OpenAIStream, AIMessage
using Anthropic: StreamMeta, call_cost!, initStreamMeta, format_meta_info

@kwdef mutable struct CvikliCallback <: AbstractStreamCallback
    out::IO = stdout
    chunks::Vector{StreamChunk} = StreamChunk[]
    content::String = ""
    verbose::Bool = false
    throw_on_error::Bool = false
    flavor::Union{Nothing, AbstractStreamFlavor} = nothing
    kwargs::NamedTuple = NamedTuple()
    stream_meta::StreamMeta = StreamMeta()
end

function PromptingTools.callback(cb::CvikliCallback, chunk::StreamChunk; kwargs...)
    processed_text = PromptingTools.extract_content(cb.flavor, chunk; kwargs...)
    isnothing(processed_text) && return nothing
    PromptingTools.print_content(cb.out, processed_text; kwargs...)
    push!(cb.chunks, chunk)
    
    if !isnothing(chunk.json)
        if haskey(chunk.json, :choices)
            for choice in chunk.json.choices
                if haskey(choice, :delta) && haskey(choice.delta, :content)
                    cb.content *= choice.delta.content
                    cb.stream_meta.output_tokens += 1
                end
            end
        end
        if haskey(chunk.json, :usage)
            usage = chunk.json.usage
            cb.stream_meta.input_tokens += get(usage, :prompt_tokens, 0)
            cb.stream_meta.cache_creation_input_tokens += get(usage, :cache_creation_input_tokens, 0)
            cb.stream_meta.cache_read_input_tokens += get(usage, :cache_read_input_tokens, 0)
        end
    end
    
    if cb.verbose
        println(cb.out, "Chunk received: ", chunk)
    end
    
    # Handle error messages
    PromptingTools.handle_error_message(chunk; throw_on_error = cb.throw_on_error)
end

function PromptingTools.configure_callback!(cb::CvikliCallback, schema::AbstractPromptSchema; api_kwargs...)
    if isnothing(cb.flavor)
        if schema isa OpenAISchema
            api_kwargs = (; api_kwargs..., stream = true)
            flavor = OpenAIStream()
        else
            error("Unsupported schema type: $(typeof(schema)). Currently supported: OpenAISchema.")
        end
        cb.flavor = flavor
    end
    return cb, api_kwargs
end

function PromptingTools.build_response_body(flavor::OpenAIStream, cb::CvikliCallback; verbose::Bool = false, kwargs...)
    isempty(cb.chunks) && return nothing
    response = nothing
    usage = Dict{Symbol, Int}(:prompt_tokens => 0, :completion_tokens => 0, :total_tokens => 0)
    choices_output = Dict{Int, Dict{Symbol, Any}}()
    for i in eachindex(cb.chunks)
        chunk = cb.chunks[i]
        ## validate that we can access choices
        isnothing(chunk.json) && continue
        !haskey(chunk.json, :choices) && continue
        if isnothing(response)
            ## do it only once the first time when we have the json
            response = chunk.json |> copy
        end
        if haskey(chunk.json, :usage)
            usage_values = chunk.json[:usage]
            for (key, value) in usage_values
                usage[Symbol(key)] = get(usage, Symbol(key), 0) + value
            end
        end
        for choice in chunk.json.choices
            index = get(choice, :index, nothing)
            isnothing(index) && continue
            if !haskey(choices_output, index)
                choices_output[index] = Dict{Symbol, Any}(:index => index)
            end
            index_dict = choices_output[index]
            finish_reason = get(choice, :finish_reason, nothing)
            if !isnothing(finish_reason)
                index_dict[:finish_reason] = finish_reason
            end
            choice_delta = get(choice, :delta, Dict{Symbol, Any}())
            message_dict = get(index_dict, :message, Dict{Symbol, Any}(:content => ""))
            role = get(choice_delta, :role, nothing)
            if !isnothing(role)
                message_dict[:role] = role
            end
            content = get(choice_delta, :content, nothing)
            if !isnothing(content)
                message_dict[:content] *= content
            end
            index_dict[:message] = message_dict
        end
    end
    ## We know we have at least one chunk, let's use it for final response
    if !isnothing(response)
        # flatten the choices_dict into an array
        choices = [choices_output[index] for index in sort(collect(keys(choices_output)))]
        # overwrite the old choices
        response[:choices] = choices
        response[:object] = "chat.completion"
        response[:usage] = usage
    end
    return response
end
