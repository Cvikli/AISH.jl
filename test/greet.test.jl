
using Test
include("../src/greeting.jl")

println("Hi from the greet test file!")

@testset "Greeting Test" begin
    @test greet("World") == "Hello, World!"
    @test greet("User", "Hi") == "Hi, User!"  # New test case
    @test greet("Orion") == "Hello, Orion!"  # New test case
end

# ... existing code ...

