using Test
include("../src/greeting.jl")

@testset "Greeting Test" begin
    @test greet("User") == "Hi, User!"
    @test greet("World") == "Hi, World!"
end
