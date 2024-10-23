
using Test
include("../src/greeting.jl")

@testset "Greeting Test" begin
    @test greet("World") == "Hello, World!"
    @test greet("Assistant") == "Hello, Assistant!"
    @test greet("Julia", "Hi") == "Hi, Julia!"
end

# ... existing code ...

