
# Add this line to include the new greeting function
include("../src/greeting.jl")

# Add this test before the start() function call
@testset "Greeting Test" begin
    @test greet("World") == "Hello, World!"
end

# ... existing code ...

