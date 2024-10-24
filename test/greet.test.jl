using Test
include("../src/greeting.jl")

println("Hi from the greet test file!")

@testset "Greeting Test" begin
    @test greet("User", "Hello") == "Hello, User! Here's a positive addition: 0 + 1 = 1"
    @test greet("World") == "Hi, World! Here's a positive addition: 0 + 1 = 1"
    @test greet("Orion") == "Hi, Orion! Here's a positive addition: 0 + 1 = 1"
    @test greet("User") == "Hi, User! Here's a positive addition: 0 + 1 = 1"
    @test greet("Math", "Hello", 5) == "Hello, Math! Here's a positive addition: 5 + 1 = 6"
    @test greet("Negative", "Hey", -3) == "Hey, Negative! Here's a positive addition: 3 + 1 = 4"
end
