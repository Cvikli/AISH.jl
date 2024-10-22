
using Test
include("../src/greeting.jl")

@testset "Greeting Test" begin
    @test greet("World") == "Hello, World!"
end

# ... existing code ...

