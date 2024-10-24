
using Test
include("../src/greeting.jl")

println("Hi from the greet test file!")

@testset "Greeting Test" begin
    @test greet("User", "Hello") == "Hello, User!"
    @test greet("World") == "Hi, World!"
    @test greet("Orion") == "Hi, Orion!"
    @test greet("User") == "Hi, User!"  # New test case
end

# ... existing code ...

