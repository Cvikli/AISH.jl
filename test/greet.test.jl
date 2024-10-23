
using Test
include("../src/greeting.jl")

println("Hi from the greet test file!")

@testset "Greeting Test" begin
    @test greet("World") == "Hello, World!"
    @test greet("Assistant") == "Hello, Assistant!"
    @test greet("Julia", "Hi") == "Hi, Julia!"
    @test greet("Test", "Hi") == "Hi, Test!"  # Added new test case
    @test greet("User", "Hi") == "Hi, User!"  # New test case
end

# ... existing code ...

