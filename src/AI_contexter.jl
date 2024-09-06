
abstract type AbstractContextCreator end

@kwdef struct SimpleContexter <: AbstractContextCreator
    keep::Int = 7
end

function get_cache_setting(::AbstractContextCreator, conv)
    printstyled("WARNING: get_cache_setting not implemented for this contexter type. Defaulting to no caching.\n", color=:red)
    return nothing
end

function get_cache_setting(::SimpleContexter, conv)
    return nothing
end

