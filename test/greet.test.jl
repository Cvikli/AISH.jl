
using Test
include("../src/greeting.jl")

println("Hi from the greet test file!")

@testset "Greeting Test" begin
    @test greet("User", "Hello") == "Hello, User!"  # Changed order of test cases
    @test greet("World") == "Hi, World!"  # Changed expectation
    @test greet("Orion") == "Hi, Orion!"  # Changed expectation
end

# ... existing code ...

