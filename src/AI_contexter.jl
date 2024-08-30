
abstract type AbstractContextCreator end

@kwdef struct SimpleContexter <: AbstractContextCreator
    keep::Int=7
end

